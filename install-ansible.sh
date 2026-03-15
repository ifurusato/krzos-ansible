#!/bin/bash

set -e
echo "=== Installing Ansible on desktop ==="

echo "Creating Python venv..."
python3 -m venv ~/ansible-venv

echo "Installing Ansible..."
~/ansible-venv/bin/pip install --upgrade ansible

echo "Creating shell environment files..."
cat > ~/.ansible_env.sh << 'EOF'
# Ansible venv
export ANSIBLE_VENV="$HOME/ansible-venv"
alias ansible="$ANSIBLE_VENV/bin/ansible"
alias ansible-playbook="$ANSIBLE_VENV/bin/ansible-playbook"
alias ansible-galaxy="$ANSIBLE_VENV/bin/ansible-galaxy"
alias ansible-vault="$ANSIBLE_VENV/bin/ansible-vault"
EOF

cat > ~/.ansible_env.csh << 'EOF'
# Ansible venv
setenv ANSIBLE_VENV "$HOME/ansible-venv"
alias ansible "$ANSIBLE_VENV/bin/ansible"
alias ansible-playbook "$ANSIBLE_VENV/bin/ansible-playbook"
alias ansible-galaxy "$ANSIBLE_VENV/bin/ansible-galaxy"
alias ansible-vault "$ANSIBLE_VENV/bin/ansible-vault"
EOF

echo "Ansible installed successfully:"
~/ansible-venv/bin/ansible --version | head -1
echo ""
echo "Add the following line to your shell rc file:"
echo "  tcsh:  source ~/.ansible_env.csh"
echo "  bash:  source ~/.ansible_env.sh"
