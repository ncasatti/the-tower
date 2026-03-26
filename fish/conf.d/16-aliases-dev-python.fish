# ====================
# Python Development Aliases
# ====================
# Python, pip, and virtual environment shortcuts

# Pip commands
abbr -a pipi 'pip install'
abbr -a pipu 'pip install --upgrade pip'
abbr -a pipir 'pip install -r requirements.txt'
abbr -a pipclean 'pip freeze > pip-uninstall && pip uninstall -r pip-uninstall -y && rm pip-uninstall'

# Virtual environments
abbr -a conda-env 'source /home/ncasatti/.local/share/Uts/.sdk/anaconda3/bin/activate'
abbr -a env-aws 'source ~/Documents/Development/Python/.venv/aws/bin/activate'
abbr -a penv1 'source ~/Documents/Development/Python/.venv/research-corteva-cba/bin/activate'
abbr -a penv2 'source ~/Documents/Development/Python/.venv/research-corteva-cba36/bin/activate'
abbr -a penv-aws 'source ~/Documents/Development/Python/.venv/aws/bin/activate'
abbr -a enva 'source .venv/bin/activate.fish'

# Python shortcuts
abbr -a pym 'python manage.py'
abbr -a p python
abbr -a pb 'black --line-length 100 && isort --profile black'
