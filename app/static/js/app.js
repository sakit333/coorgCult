// Add event listener for Enter key to submit
document.getElementById('prompt').addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
        sendData();
    }
});

async function sendData() {
    const promptInput = document.getElementById("prompt");
    const prompt = promptInput.value.trim();
    const responseEle = document.getElementById("response");
    const submitBtn = document.getElementById("send-btn");
    
    if (!prompt) return;

    // UI Loading State
    responseEle.innerText = "Processing your request...";
    responseEle.classList.add("active");
    responseEle.style.color = "var(--text-secondary)";
    
    submitBtn.style.opacity = "0.7";
    submitBtn.style.pointerEvents = "none";
    submitBtn.querySelector('span').innerText = "Sending...";

    console.log("Sending prompt:", prompt, "| Session:", window.session_id);
    
    try {
        const response = await fetch("/api/generate", {
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
        
        responseEle.style.color = "var(--text-primary)";
        if (data && data.response) {
            responseEle.innerText = data.response;
        } else {
            responseEle.innerText = "Received response, but the format was unexpected.";
        }
        
    } catch (error) {
        console.error("Error connecting to API:", error);
        responseEle.innerText = "Something went wrong. Please check your connection and try again.";
        responseEle.style.color = "#ef4444"; // Red for error
    } finally {
        // Reset button and clear input
        submitBtn.style.opacity = "1";
        submitBtn.style.pointerEvents = "auto";
        submitBtn.querySelector('span').innerText = "Send";
        promptInput.value = "";
    }
}