#!/bin/bash
set -e

# Cleanup script for EKS resources that prevent terraform destroy
# This script removes ENIs and load balancers that EKS/Fargate leaves behind

VPC_ID="$1"
CLUSTER_NAME="$2"
AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "Cleaning up EKS resources for cluster: $CLUSTER_NAME in VPC: $VPC_ID"

# Update kubeconfig if needed
echo "Updating kubeconfig..."
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME" --output table || true

# Force delete Helm releases first to prevent hanging
echo "Force deleting Helm releases..."
helm list --all-namespaces --short | grep -v NAME | while read -r release namespace; do
    if [ -n "$release" ]; then
        echo "Force deleting Helm release: $release in namespace: $namespace"
        helm delete "$release" --namespace "$namespace" --timeout 120s --wait || true
    fi
done

# Clean up any remaining ingresses and services that might create load balancers
echo "Cleaning up Kubernetes resources..."
kubectl delete ingress --all --all-namespaces --timeout=60s --ignore-not-found=true --force --grace-period=0 || true
kubectl delete svc --field-selector spec.type=LoadBalancer --all-namespaces --timeout=60s --ignore-not-found=true --force --grace-period=0 || true

# Wait for load balancers to be cleaned up
echo "Waiting for load balancers to be deleted..."
sleep 60

# Clean up any remaining load balancers in AWS
echo "Cleaning up AWS Load Balancers..."
aws elbv2 describe-load-balancers --region "$AWS_REGION" --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text | tr '\t' '\n' | while read -r lb_arn; do
    if [ -n "$lb_arn" ]; then
        echo "Deleting Load Balancer: $lb_arn"
        aws elbv2 delete-load-balancer --region "$AWS_REGION" --load-balancer-arn "$lb_arn" || true
    fi
done

# Wait for ELBs to be fully cleaned up
sleep 30

# Force delete ENIs that are unattached and related to EKS/Fargate
echo "Cleaning up unattached EKS/Fargate ENIs in VPC: $VPC_ID"
aws ec2 describe-network-interfaces \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=status,Values=available" \
    --query "NetworkInterfaces[?starts_with(Description, 'EKS') || contains(Description, 'fargate')].NetworkInterfaceId" \
    --output text | tr '\t' '\n' | while read -r eni_id; do
    if [ -n "$eni_id" ]; then
        echo "Deleting unattached EKS/Fargate ENI: $eni_id"
        aws ec2 delete-network-interface --region "$AWS_REGION" --network-interface-id "$eni_id" || true
    fi
done

# Clean up any remaining Elastic IPs
echo "Cleaning up Elastic IPs..."
aws ec2 describe-addresses \
    --region "$AWS_REGION" \
    --query "Addresses[?AssociationId == null].AllocationId" \
    --output text | tr '\t' '\n' | while read -r alloc_id; do
    if [ -n "$alloc_id" ]; then
        echo "Releasing Elastic IP: $alloc_id"
        aws ec2 release-address --region "$AWS_REGION" --allocation-id "$alloc_id" || true
    fi
done

# Clean up AWS Load Balancer Controller security groups
echo "Cleaning up AWS Load Balancer Controller security groups..."
aws ec2 describe-security-groups \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "SecurityGroups[?starts_with(GroupName, 'k8s-') || contains(Description, 'k8s')].GroupId" \
    --output text | tr '\t' '\n' | while read -r sg_id; do
    if [ -n "$sg_id" ]; then
        echo "Deleting AWS Load Balancer Controller Security Group: $sg_id"
        aws ec2 delete-security-group --region "$AWS_REGION" --group-id "$sg_id" || true
    fi
done

# Force cleanup of AWS Load Balancer Controller resources that have finalizers
echo "Cleaning up AWS Load Balancer Controller resources with finalizers..."
for namespace in apps default kube-system; do
    if kubectl get namespace "$namespace" 2>/dev/null >/dev/null; then
        echo "Cleaning AWS LB Controller resources in namespace: $namespace"
        
        # Remove finalizers from ingresses
        kubectl get ingress -n "$namespace" -o name 2>/dev/null | while read -r ingress; do
            if [ -n "$ingress" ]; then
                echo "Removing finalizers from $ingress"
                kubectl patch "$ingress" -n "$namespace" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
            fi
        done
        
        # Remove finalizers from target group bindings
        kubectl get targetgroupbindings -n "$namespace" -o name 2>/dev/null | while read -r tgb; do
            if [ -n "$tgb" ]; then
                echo "Removing finalizers from $tgb"
                kubectl patch "$tgb" -n "$namespace" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
            fi
        done
        
        # Force delete these resources
        kubectl delete ingress --all -n "$namespace" --timeout=10s --ignore-not-found=true --force --grace-period=0 || true
        kubectl delete targetgroupbindings --all -n "$namespace" --timeout=10s --ignore-not-found=true --force --grace-period=0 || true
    fi
done

# Force cleanup of stuck namespaces by removing finalizers
echo "Force cleaning up stuck namespaces..."
for namespace in apps default kube-system; do
    if kubectl get namespace "$namespace" 2>/dev/null | grep -q "Terminating"; then
        echo "Removing finalizers from stuck namespace: $namespace"
        kubectl patch namespace "$namespace" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        kubectl delete namespace "$namespace" --force --grace-period=0 || true
    fi
done

echo "Cleanup completed"