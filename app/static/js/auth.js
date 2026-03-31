document.addEventListener("DOMContentLoaded", () => {
    const loginForm = document.getElementById("login-form");
    const signupForm = document.getElementById("signup-form");
    const errorMsg = document.getElementById("error-message");
    const successMsg = document.getElementById("success-message");
    const submitBtn = document.getElementById("submit-btn");

    function showError(msg) {
        if (!errorMsg) return;
        errorMsg.innerText = msg;
        errorMsg.style.display = "block";
    }

    function hideError() {
        if (!errorMsg) return;
        errorMsg.style.display = "none";
        errorMsg.innerText = "";
    }

    // ✅ FINAL SAFE UUID GENERATOR
    function generateUUID() {
        try {
            if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
                return crypto.randomUUID();
            }
        } catch (e) {
            console.warn("crypto.randomUUID not available, using fallback");
        }

        // Fallback (works everywhere)
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
            const r = Math.random() * 16 | 0;
            const v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }

    // ---------------- LOGIN ----------------
    if (loginForm) {
        loginForm.addEventListener("submit", async (e) => {
            e.preventDefault();
            hideError();

            const username = document.getElementById("username").value.trim();
            const password = document.getElementById("password").value;

            if (!username || !password) {
                return showError("Both username and password are required.");
            }

            submitBtn.style.opacity = "0.7";
            submitBtn.style.pointerEvents = "none";
            submitBtn.querySelector("span").innerText = "Logging in...";

            try {
                const res = await fetch("/api/v1/auth/login", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ username, password })
                });

                const data = await res.json();

                if (!res.ok) {
                    throw new Error(data.detail || "Invalid credentials.");
                }

                // ✅ SAFE SESSION ID
                let sessionId = localStorage.getItem("session_id");
                if (!sessionId) {
                    sessionId = generateUUID();
                    localStorage.setItem("session_id", sessionId);
                }

                localStorage.setItem("access_token", data.access_token);

                window.location.href = `/home/${sessionId}`;

            } catch (err) {
                showError(err.message || "Login failed");
            } finally {
                submitBtn.style.opacity = "1";
                submitBtn.style.pointerEvents = "auto";
                submitBtn.querySelector("span").innerText = "Log In";
            }
        });
    }

    // ---------------- SIGNUP ----------------
    if (signupForm) {
        signupForm.addEventListener("submit", async (e) => {
            e.preventDefault();
            hideError();
            if (successMsg) successMsg.style.display = "none";

            const username = document.getElementById("username").value.trim();
            const email = document.getElementById("email").value.trim();
            const password = document.getElementById("password").value;

            if (password.length < 8) {
                return showError("Password must be at least 8 characters long.");
            }
            if (password.length > 50) {
                return showError("Password must be at most 50 characters long.");
            }

            submitBtn.style.opacity = "0.7";
            submitBtn.style.pointerEvents = "none";
            submitBtn.querySelector("span").innerText = "Creating account...";

            try {
                const res = await fetch("/api/v1/auth/signup", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ username, email, password })
                });

                const data = await res.json();

                if (!res.ok) {
                    const errMsg = Array.isArray(data.detail)
                        ? data.detail[0].msg
                        : data.detail;

                    throw new Error(errMsg || "Failed to create account.");
                }

                signupForm.reset();

                if (successMsg) {
                    successMsg.innerText = "Account created successfully! Redirecting...";
                    successMsg.style.display = "block";
                }

                setTimeout(() => {
                    window.location.href = "/login";
                }, 500);

            } catch (err) {
                showError(err.message || "Signup failed");
            } finally {
                submitBtn.style.opacity = "1";
                submitBtn.style.pointerEvents = "auto";
                submitBtn.querySelector("span").innerText = "Sign Up";
            }
        });
    }
});