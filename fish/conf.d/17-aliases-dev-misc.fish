# ====================
# Miscellaneous Development Aliases
# ====================
# Go, AWS, NixOS, and other development tools

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

# NixOS
abbr -a nrs 'sudo nixos-rebuild switch'
abbr -a nr-grid 'sudo nixos-rebuild switch --flake ~/.the-grid/the-tower#the-grid'
abbr -a nrt 'sudo nixos-rebuild test'
abbr -a ne 'sudo -E nvim /etc/nixos/configuration.nix'
abbr -a ng 'sudo nix-collect-garbage'
abbr -a ngd 'sudo nix-collect-garbage -d'
abbr -a nu 'sudo nixos-rebuild switch --upgrade-all'
abbr -a nd 'nix develop -c zsh'
abbr -a nf 'vim flake.nix'
