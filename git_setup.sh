#!/bin/zsh

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
ORANGE='\033[1;38;5;100m'
NC='\033[0m' # No Color

# Prompt for user's name and email
echo -e "${GREEN}Enter your fullname or login:${NC} \c"
read NAME
echo -e "${GREEN}Enter your email:${NC} \c"
read EMAIL

# Confirm the input
echo -e "\n${YELLOW}You have entered the following details:${NC}"
echo -e "${GREEN}Name :${NC} $NAME"
echo -e "${GREEN}Email:${NC} $EMAIL"
echo -e "${YELLOW}Is this correct? (y/n):${NC} \c"
read CONFIRMATION

# Check confirmation
if [[ $CONFIRMATION == "y" || $CONFIRMATION == "Y" ]]; then
  # Git configuration
  git config --global credential.helper store
  git config --global user.email "$EMAIL"
  git config --global user.name "$NAME"

  # Confirmation message
  echo -e "\n\033[1:0;32mGit has been configured with the following details:${NC}"
  echo -e "${GREEN}Name :${NC} $NAME"
  echo -e "${GREEN}Email:${NC} $EMAIL"
else
  echo -e "\n${ORANGE}Aborted. No changes have been made.${NC}"
fi

