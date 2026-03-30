document.addEventListener('DOMContentLoaded', () => {
    // Load existing history when page loads
    if (window.session_id) {
        loadHistory();
    }
});

// Add event listener for Enter key to submit
document.getElementById('prompt').addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
        sendData();
    }
});

const chatHistoryContainer = document.getElementById('chat-history-container');

function appendMessage(role, text) {
    const msgDiv = document.createElement('div');
    msgDiv.classList.add('chat-message', role === 'User' ? 'user' : 'ai');
    
    if (text === "typing...") {
        msgDiv.id = "typing-indicator";
        msgDiv.innerHTML = `<div class="typing-indicator"><span></span><span></span><span></span></div>`;
    } else {
        // Strip out prefixed labels if they exist in history (e.g., "User: Hello")
        let displayText = text;
        if (role === 'User' && text.startsWith("User: ")) displayText = text.slice(6);
        if (role === 'AI' && text.startsWith("AI: ")) displayText = text.slice(4);
        
        msgDiv.innerText = displayText;
    }
    
    chatHistoryContainer.appendChild(msgDiv);
    chatHistoryContainer.scrollTop = chatHistoryContainer.scrollHeight;
}

function removeTypingIndicator() {
    const indicator = document.getElementById("typing-indicator");
    if (indicator) indicator.remove();
}

async function loadHistory() {
    try {
        const response = await fetch(`/api/v1/history/${window.session_id}`);
        const data = await response.json();
        if (data.history && data.history.length > 0) {
            chatHistoryContainer.innerHTML = ''; // clear initial state
            data.history.forEach(msg => {
                if (msg.startsWith("User:")) {
                    appendMessage("User", msg);
                } else if (msg.startsWith("AI:")) {
                    appendMessage("AI", msg);
                }
            });
        }
    } catch (error) {
        console.error("Failed to load history:", error);
    }
}

async function clearChat() {
    if (!confirm("Are you sure you want to delete this chat history?")) return;
    
    try {
        const response = await fetch(`/api/v1/history/${window.session_id}`, {
            method: 'DELETE'
        });
        
        if (response.ok) {
            chatHistoryContainer.innerHTML = '';
        } else {
            alert("Failed to clear chat");
        }
    } catch (error) {
        console.error("Failed to clear chat:", error);
    }
}

async function sendData() {
    const promptInput = document.getElementById("prompt");
    const prompt = promptInput.value.trim();
    const submitBtn = document.getElementById("send-btn");
    
    if (!prompt) return;

    // Instantly show user message
    appendMessage("User", prompt);
    promptInput.value = "";
    
    // Show AI typing indicator
    appendMessage("AI", "typing...");
    
    submitBtn.style.opacity = "0.7";
    submitBtn.style.pointerEvents = "none";
    submitBtn.querySelector('span').innerText = "Sending...";

    console.log("Sending prompt:", prompt, "| Session:", window.session_id);
    
    try {
        const response = await fetch("/api/v1/generate", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ 
                prompt: prompt, 
                session_id: window.session_id 
            })
        });
        
        const data = await response.json();
        removeTypingIndicator();
        
        if (data && data.response) {
            appendMessage("AI", data.response);
        } else {
            appendMessage("AI", "Received response, but the format was unexpected.");
        }
        
    } catch (error) {
        removeTypingIndicator();
        console.error("Error connecting to API:", error);
        appendMessage("AI", "Error: Something went wrong. Please check your connection and try again.");
    } finally {
        submitBtn.style.opacity = "1";
        submitBtn.style.pointerEvents = "auto";
        submitBtn.querySelector('span').innerText = "Send";
    }
}