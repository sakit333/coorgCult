#!/bin/bash
# Update and install nginx
sudo apt update -y
sudo apt install -y nginx

# Create custom HTML content
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>DevOps Lab by @sak_shetty</title>
  <style>
    :root {
      --primary-color: #007bff;
      --background-gradient: linear-gradient(135deg, #e0f7fa, #ffffff);
      --text-color: #333;
      --muted-color: #666;
      --footer-bg: #eaecef;
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      padding: 0;
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background: var(--background-gradient);
      color: var(--text-color);
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      position: relative;
      overflow: hidden;
    }

    .bg-shape {
      position: absolute;
      border-radius: 50%;
      opacity: 0.1;
      animation: float 20s infinite linear;
      z-index: 0;
    }

    .bg1 {
      width: 300px;
      height: 300px;
      background: #007bff;
      top: -100px;
      left: -100px;
    }

    .bg2 {
      width: 200px;
      height: 200px;
      background: #00bcd4;
      bottom: -80px;
      right: -60px;
    }

    @keyframes float {
      0% {
        transform: translateY(0) rotate(0deg);
      }
      100% {
        transform: translateY(-20px) rotate(360deg);
      }
    }

    .card {
      background-color: #fff;
      padding: 50px;
      max-width: 700px;
      width: 95%;
      border-radius: 12px;
      box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
      text-align: center;
      z-index: 1;
    }

    h1 {
      font-size: 2.5em;
      color: var(--primary-color);
      margin-bottom: 10px;
    }

    h2 {
      font-size: 1.3em;
      color: var(--muted-color);
      font-weight: normal;
      margin-top: 0;
      margin-bottom: 30px;
    }

    p {
      font-size: 1.1em;
      line-height: 1.6;
      color: #555;
      margin: 10px 0;
    }

    .highlight {
      font-weight: bold;
      color: var(--primary-color);
    }

    .author {
      margin-top: 30px;
      font-size: 1em;
      color: #444;
    }

    .author strong {
      color: var(--primary-color);
    }

    footer {
      margin-top: 40px;
      font-size: 0.9em;
      background-color: var(--footer-bg);
      padding: 15px;
      border-radius: 8px;
      color: #777;
    }

    @media (max-width: 768px) {
      .card {
        padding: 40px 25px;
      }

      h1 {
        font-size: 2em;
      }

      h2 {
        font-size: 1.1em;
      }

      p {
        font-size: 1em;
      }
    }

    @media (max-width: 480px) {
      .card {
        padding: 30px 20px;
      }

      h1 {
        font-size: 1.8em;
      }

      h2 {
        font-size: 1em;
      }

      p {
        font-size: 0.95em;
      }

      .author {
        font-size: 0.95em;
      }

      footer {
        font-size: 0.85em;
      }
    }
  </style>
</head>
<body>
  <!-- Animated Background Elements -->
  <div class="bg-shape bg1"></div>
  <div class="bg-shape bg2"></div>

  <div class="card">
    <h1>Welcome to Your DevOps Lab</h1>
    <h2>Powered by Terraform & NGINX on AWS</h2>
    <p>
      This environment is <span class="highlight">infrastructure-as-code</span> in action, 
      provisioned via <span class="highlight">Terraform</span> and configured with <span class="highlight">NGINX</span> to serve this landing page.
    </p>
    <p>
      Designed for students and professionals to practice core concepts of 
      <span class="highlight">cloud infrastructure</span>, <span class="highlight">automation</span>, 
      and <span class="highlight">DevOps workflows</span>.
    </p>
    <div class="author">
      Crafted by <strong>Akshay Kumar S</strong> — DevOps Engineer & Freelancer
    </div>
    <footer>
      &copy; 2025 <strong>@sak_shetty</strong>. All rights reserved. | Empowering DevOps Education
    </footer>
  </div>
</body>
</html>
EOF

# Ensure nginx is running
sudo systemctl enable nginx
sudo systemctl restart nginx
