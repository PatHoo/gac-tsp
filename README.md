### Terraform AWS for GAC's TSP

- AWS WorkShop: https://tf-eks-workshop.workshop.aws
- EKS Best Practice: https://aws.github.io/aws-eks-best-practices
- EKS BluePrints: https://aws-ia.github.io/terraform-aws-eks-blueprints
- EKS BluePrints WorkLoads: https://github.com/aws-samples/eks-blueprints-workloads
- Terraform Modules: https://registry.terraform.io/namespaces/terraform-aws-modules
- EKS Max Pods: https://github.com/awslabs/amazon-eks-ami/blob/master/files/eni-max-pods.txt
- EKS Spot EC2: https://aws.amazon.com/cn/blogs/china/eks-use-spot-instance-best-practice/?nc1=b_nrp

To select EC2 instance, run command:
```
ec2-instance-selector --vcpus 4 --memory 8 --cpu-architecture x86_64 -r ap-southeast-1
```
