async function sendData() {
    const prompt = document.getElementById("prompt").value;

    const response = await fetch("/api/v1/generate", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({ prompt: prompt })
    });

    const data = await response.json();

    document.getElementById("output").innerText = data.response;
}