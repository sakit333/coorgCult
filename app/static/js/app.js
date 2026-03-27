async function sendData() {
    const prompt = document.getElementById("prompt").value;
    console.log(prompt, window.session_id);
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
        document.getElementById("response").innerText = data.response;
    } catch (error) {
        console.error("Error:", error);
        document.getElementById("response").innerText = "Something went wrong. Please try again.";
    }
}