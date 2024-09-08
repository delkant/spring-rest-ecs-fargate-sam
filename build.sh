# Config file path
CONFIG_FILE=infra/config.txt

# If config file exists, read values from it
if [ -f "$CONFIG_FILE" ]; then

  echo "Reading config file..."

  # Read values 
  source $CONFIG_FILE

  # Set variables from config
  IMAGE_NAME=$image_name
  REPO_NAME=$repo_name
  AWS_ACCOUNT=$aws_account
  AWS_REGION=$aws_region

else

  # Prompt for inputs
  read -p "Enter image name: " IMAGE_NAME
  read -p "Enter repository name: " REPO_NAME  
  read -p "Enter AWS account ID: " AWS_ACCOUNT
  read -p "Enter AWS Region: " AWS_REGION

  # Save inputs to config file
  echo "Saving config..."
  echo "image_name=$IMAGE_NAME" > $CONFIG_FILE
  echo "repo_name=$REPO_NAME" >> $CONFIG_FILE
  echo "aws_account=$AWS_ACCOUNT" >> $CONFIG_FILE
  echo "aws_region=$AWS_REGION" >> $CONFIG_FILE

fi


# Build Docker image
# You might need to run first:
# docker buildx create --name multiarch --driver docker-container --use
#
docker buildx build --platform linux/amd64 -t $IMAGE_NAME . -f infra/Dockerfile --load
# Check if repository exists
REPO_EXISTS=$(aws ecr describe-repositories --repository-names $REPO_NAME --region $AWS_REGION 2>&1 | grep -c RepositoryNotFoundException)

# Create ECR repository if it doesn't exist
if [ $REPO_EXISTS -eq 1 ]; then
  aws ecr create-repository --repository-name $REPO_NAME --region $AWS_REGION
fi

# Tag image 
docker tag $IMAGE_NAME $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com

# Push image to ECR
docker push $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest 

# Print image ID
IMAGE_ID=$(aws ecr describe-images --repository-name $REPO_NAME --image-ids imageTag=latest --region $AWS_REGION --query 'imageDetails[].imageId' --output text)

echo "Pushed image URI: $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest"

echo "Deploying Infra.."
VPC_STACK_NAME='vpc-stack'
IAM_STACK_NAME=iam-stack
CLUSTER_STACK_NAME=rest-srv-cluster-stack

# Get stacks status
VPC_STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $VPC_STACK_NAME --query "Stacks[0].StackStatus" --output text 2>/dev/null)

# Check if the vpc stack exists
if [ $? -ne 0 ]; then
  aws cloudformation create-stack --template-body file://$PWD/infra/vpc.yml --stack-name vpc-stack
  echo "Done. Stack '$VPC_STACK_NAME' Creation in Progress."
elif [ "$VPC_STACK_STATUS" == "CREATE_COMPLETE" ]; then
  echo "Done. Stack '$VPC_STACK_NAME' already exists and is in CREATE_COMPLETE status."
else
  echo "ERROR. Stack '$VPC_STACK_NAME' exists but is in '$VPC_STACK_STATUS' status."
  exit 1
fi

IAM_STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $IAM_STACK_NAME --query "Stacks[0].StackStatus" --output text 2>/dev/null)
if [ $? -ne 0 ]; then
  aws cloudformation create-stack --template-body file://$PWD/infra/iam.yml --stack-name iam-stack --capabilities CAPABILITY_IAM
  echo "Done. Stack '$IAM_STACK_NAME' Creation in Progress."
elif [ "$IAM_STACK_STATUS" == "CREATE_COMPLETE" ]; then
  echo "Done. Stack '$IAM_STACK_NAME' already exists and is in CREATE_COMPLETE status."
else
  echo "ERROR. Stack '$IAM_STACK_NAME' exists but is in '$IAM_STACK_STATUS' status."
  exit 1
fi

CLUSTER_STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $CLUSTER_STACK_NAME --query "Stacks[0].StackStatus" --output text 2>/dev/null)

if [ $? -ne 0 ]; then
  aws cloudformation create-stack --template-body file://$PWD/infra/cluster.yml --stack-name rest-srv-cluster-stack
  echo "Done. Stack '$CLUSTER_STACK_NAME' Creation in Progress."
elif [ "$CLUSTER_STACK_STATUS" == "CREATE_COMPLETE" ]; then
  echo "Done. Stack '$CLUSTER_STACK_NAME' already exists and is in CREATE_COMPLETE status."
else
  echo "ERROR. Stack '$CLUSTER_STACK_NAME' exists but is in '$CLUSTER_STACK_STATUS' status."
  exit 1
fi


