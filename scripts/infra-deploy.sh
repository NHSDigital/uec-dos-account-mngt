#! /bin/bash
# You will need to export
# ACTION eg plan, apply, destroy
# STACK eg iam-policy
# ENVIRONMENT eg dev,test
# PROJECT eg dos or cm

# functions
source ./scripts/functions/terraform-functions.sh

export ACTION="${ACTION:-""}"               # The terraform action to execute
export STACK="${STACK:-""}"                 # The terraform stack to be actioned
export ENVIRONMENT="${ENVIRONMENT:-""}"     # The environment to build
export PROJECT="${PROJECT:-""}"             # dos or cm
export USE_REMOTE_STATE_STORE="${USE_REMOTE_STATE_STORE:-true}"
# check exports have been done
EXPORTS_SET=0
# Check key variables have been exported - see above
if [ -z "$ACTION" ] ; then
  echo Set ACTION to terraform action one of plan apply or destroy
  EXPORTS_SET=1
fi

if [ -z "$STACK" ] ; then
  echo Set STACK to name of the stack to be planned, applied, destroyed
  EXPORTS_SET=1
fi

if [ -z "$ENVIRONMENT" ] ; then
  echo Set ENVIRONMENT type of environment - one of dev, test, preprod, prod
  EXPORTS_SET=1
fi

if [ -z "$PROJECT" ] ; then
  echo Set PROJECT to dos or cm
  EXPORTS_SET=1
fi

if [ $EXPORTS_SET = 1 ] ; then
  echo One or more exports not set
  exit 1
fi

COMMON_TF_VARS_FILE="common.tfvars"
PROJECT_TF_VARS_FILE="$PROJECT-project.tfvars"
ENV_TF_VARS_FILE="$ENVIRONMENT.tfvars"
echo "Preparing to run terraform $ACTION for stack $STACK for environment $ENVIRONMENT and project $PROJECT"
ROOT_DIR=$PWD

# the directory that holds the stack to terraform
STACK_DIR=$PWD/$INFRASTRUCTURE_DIR/stacks/$STACK
#  copy shared tf files to stack
if [[ "$USE_REMOTE_STATE_STORE" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON) ]]; then
  cp "$ROOT_DIR"/"$INFRASTRUCTURE_DIR"/shared/versions.tf "$STACK_DIR"
  cp "$ROOT_DIR"/"$INFRASTRUCTURE_DIR"/shared/locals.tf "$STACK_DIR"
  cp "$ROOT_DIR"/"$INFRASTRUCTURE_DIR"/shared/provider.tf "$STACK_DIR"
fi
# switch to target stack directory ahead of tf init/plan/apply
cd "$STACK_DIR" || exit
# init terraform
terraform-initialise "$STACK" "$ENVIRONMENT" "$USE_REMOTE_STATE_STORE"
# plan
if [ -n "$ACTION" ] && [ "$ACTION" = 'plan' ] ; then
  terraform plan \
  -var-file $ROOT_DIR/$INFRASTRUCTURE_DIR/$COMMON_TF_VARS_FILE \
  -var-file $ROOT_DIR/$INFRASTRUCTURE_DIR/$PROJECT_TF_VARS_FILE \
  -var-file $ROOT_DIR/$INFRASTRUCTURE_DIR/$ENV_TF_VARS_FILE
fi

if [ -n "$ACTION" ] && [ "$ACTION" = 'apply' ] ; then
  terraform apply -auto-approve \
    -var-file $ROOT_DIR/$INFRASTRUCTURE_DIR/$COMMON_TF_VARS_FILE \
    -var-file $ROOT_DIR/$INFRASTRUCTURE_DIR/$PROJECT_TF_VARS_FILE \
    -var-file $ROOT_DIR/$INFRASTRUCTURE_DIR/$ENV_TF_VARS_FILE
fi

if [ -n "$ACTION" ] && [ "$ACTION" = 'destroy' ] ; then
  terraform destroy -auto-approve\
    -var-file $ROOT_DIR/$INFRASTRUCTURE_DIR/$COMMON_TF_VARS_FILE \
    -var-file $ROOT_DIR/$INFRASTRUCTURE_DIR/$PROJECT_TF_VARS_FILE \
    -var-file $ROOT_DIR/$INFRASTRUCTURE_DIR/$ENV_TF_VARS_FILE
fi
# remove temp files
rm -f "$STACK_DIR"/locals.tf
rm -f "$STACK_DIR"/provider.tf
rm -f "$STACK_DIR"/versions.tf
