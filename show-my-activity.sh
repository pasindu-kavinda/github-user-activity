#!/bin/bash
# Author: [Pasindu Kavinda]

gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Hello, there! Welcome to $(gum style --foreground 212 'GitHub User Activity')."
sleep 0.5
echo "🚀 Do you want to see your GitHub activity summary?"
echo ""

username=$(gum input --placeholder "Enter username" --prompt "🐙 GitHub Username: ")

# Show spinning indicator while fetching data
gum spin --spinner dot --title "Reaching out on GitHub..." -- sleep 1.5
response=$(curl -s "https://api.github.com/users/$username/events")

# Check if the response contains an error message or rate limit error
if echo "$response" | grep -q '"message": "Not Found"'; then
    gum style --foreground 8 "User not found or invalid username."
    exit 1
elif echo "$response" | grep -q '"message": "API rate limit exceeded"'; then
    gum style --foreground 8 "API rate limit exceeded. Please try again later."
    exit 1
fi

# Check if response is empty or invalid JSON
if [[ -z "$response" || ! $(echo "$response" | jq .) ]]; then
    gum style --foreground 8 "No activity found or invalid response."
    exit 1
fi

echo "$username!, Here is your GitHub activity summary."
echo ""

# Extract events from the response using jq
events=$(echo "$response" | jq -c '.[]')

# Function to display activity
function displayActivity() {
    if [[ -z "$events" ]]; then
        gum style --foreground 8 "No recent activity found."
        return
    fi

    # Display each event
    echo "$events" | while IFS= read -r event; do
        eventType=$(echo "$event" | jq -r '.type')
        repoName=$(echo "$event" | jq -r '.repo.name')
        eventPayload=$(echo "$event" | jq -r '.payload')

        case "$eventType" in
        "PushEvent")
            commitCount=$(echo "$eventPayload" | jq '.commits | length')
            gum style --foreground 255 "🚀 Pushed $commitCount commit(s) to $(gum style --foreground 212 "$repoName")"
            ;;
        "IssuesEvent")
            issueAction=$(echo "$eventPayload" | jq -r '.action')
            gum style --foreground 255 "📝 ${issueAction^} an issue in $(gum style --foreground 212 "$repoName")"
            ;;
        "WatchEvent")
            gum style --foreground 255 "⭐ Starred $(gum style --foreground 212 "$repoName")"
            ;;
        "ForkEvent")
            gum style --foreground 255 "🍴 Forked $(gum style --foreground 212 "$repoName")"
            ;;
        "CreateEvent")
            refType=$(echo "$eventPayload" | jq -r '.ref_type')
            gum style --foreground 255 "🆕 Created $refType in $(gum style --foreground 212 "$repoName")"
            ;;
        *)
            gum style --foreground 255 "🎉 $eventType in $(gum style --foreground 212 "$repoName")"
            ;;
        esac
    done
}

# Call the function to display activity
displayActivity
