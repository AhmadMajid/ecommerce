#!/bin/bash

echo "Testing Mark as Read functionality via HTTP"
echo "==========================================="

# Get CSRF token and login
echo "1. Getting login page..."
curl -c cookies.txt -s http://localhost:3000/users/sign_in > login_page.html

CSRF_TOKEN=$(grep 'csrf-token' login_page.html | sed 's/.*content="\([^"]*\)".*/\1/')
echo "CSRF Token: $CSRF_TOKEN"

# Login as admin
echo "2. Logging in as admin..."
curl -c cookies.txt -b cookies.txt \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "authenticity_token=$CSRF_TOKEN&user[email]=admin@stylemart.com&user[password]=password123&commit=Log+in" \
  http://localhost:3000/users/sign_in \
  -L -s -o login_response.html

# Check contact messages list
echo "3. Getting contact messages list..."
curl -b cookies.txt \
  http://localhost:3000/admin/contact_messages \
  -s -o messages_list.html

if grep -q "Mark Read" messages_list.html; then
  echo "✅ Found 'Mark Read' button in the page"

  # Get the pending message ID
  PENDING_MSG_ID=$(grep -o 'mark_as_read_admin_contact_message_path([0-9]\+)' messages_list.html | grep -o '[0-9]\+' | head -1)
  echo "Pending message ID: $PENDING_MSG_ID"

  if [ ! -z "$PENDING_MSG_ID" ]; then
    # Test mark as read
    echo "4. Testing mark as read for message $PENDING_MSG_ID..."
    curl -b cookies.txt \
      -X PATCH \
      -H "X-CSRF-Token: $CSRF_TOKEN" \
      http://localhost:3000/admin/contact_messages/$PENDING_MSG_ID/mark_as_read \
      -L -s -o mark_read_response.html

    if grep -q "Message marked as read" mark_read_response.html; then
      echo "✅ Mark as read worked!"
    else
      echo "❌ Mark as read failed"
      echo "Response preview:"
      head -n 10 mark_read_response.html
    fi
  fi
else
  echo "❌ No 'Mark Read' button found"
  echo "Page preview:"
  grep -A 3 -B 3 "pending\|Mark" messages_list.html
fi

# Cleanup
rm -f login_page.html login_response.html messages_list.html mark_read_response.html cookies.txt
