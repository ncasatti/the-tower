# ====================
# Miscellaneous Development Aliases
# ====================
# Go, AWS and other development tools

# Go
abbr -a gor 'go run .'
abbr -a gob 'go build .'
abbr -a got 'go mod tidy'

# AWS CloudFormation
abbr -a aws-cloudf 'aws cloudformation'
abbr -a aws-cloudf-create 'aws cloudformation create-stack --stack-name'
abbr -a aws-cloudf-describe 'aws cloudformation describe-stacks --stack-name'
abbr -a aws-cloudf-delete 'aws cloudformation delete-stack --stack-name'
abbr -a aws-cloudf-list 'aws cloudformation list-stacks'
abbr -a aws-cloudf-deploy 'aws cloudformation deploy --stack-name'

# AWS ECR
abbr -a aws-ecr 'aws ecr'
abbr -a aws-ecr-describe 'aws ecr describe-images --repository-name'

abbr -a transes 'trans :es'
abbr -a transen 'trans :en'
