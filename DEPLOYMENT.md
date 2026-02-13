# Deploying Yuvam to Coolify

This guide explains how to deploy the Yuvam app to Coolify using Docker, while keeping your Firebase keys secure.

## Prerequisites

- You have pushed your code to GitHub.
- You have a running instance of Coolify.

## Step 1: Prepare Your Secret Key

Since we removed `lib/firebase_options.dart` from git for security, we need to provide it to the build server via an Environment Variable.

1.  **Encode the file to Base64**:
    Open a terminal in your project root and run:

    **Windows (PowerShell):**
    ```powershell
    [Convert]::ToBase64String([IO.File]::ReadAllBytes('lib/firebase_options.dart')) | Set-Clipboard
    ```
    *This will copy the base64 string directly to your clipboard.*

    **Mac/Linux:**
    ```bash
    base64 -i lib/firebase_options.dart | pbcopy
    ```
    *(Use `xclip` or `xsel` on Linux if `pbcopy` is not available, or just cat and copy)*

2.  **Paste and Save**: Keep this string safe appropriately, you will need it in the next step.

## Step 2: Configure Coolify

1.  **Create a New Resource**:
    - Go to your Coolify dashboard.
    - Click **+ New Resource**.
    - Select **Public Repository** (or Private if your repo is private).
    - Enter your repository URL: `https://github.com/yourusername/yuvam`.
    - Build Pack: Select **Docker** (or Dockerfile).

2.  **Configure Build**:
    - Coolify should automatically detect the `Dockerfile` in the root.
    - If asked for the **Docker Context**, use `.`.
    - If asked for the **Dockerfile Path**, use `./Dockerfile`.

3.  **Add Environment Variable**:
    - Go to the **Environment Variables** (Secrets) tab for your new resource.
    - Add a new variable:
        - **Name**: `FIREBASE_OPTIONS_BASE64`
        - **Value**: [Paste the base64 string you copied in Step 1]
    - **Mark as Build Variable**: Ensure you check "Build Variable" or "Is Build Time?" because this is needed during the `docker build` process.

## Step 3: Deploy

1.  Click **Deploy**.
2.  Watch the logs. You should see a step where it decodes the secret:
    ```
    RUN echo "$FIREBASE_OPTIONS_BASE64" | base64 -d > lib/firebase_options.dart
    ```
3.  Once the build finishes, your app should be live!

## Validation

- Open the deployment URL provided by Coolify.
- Check the browser console (F12) to ensure there are no Firebase initialization errors.

## Coolify Configuration Reference

Use these settings in your Coolify dashboard:

| Setting | Value | Note |
| :--- | :--- | :--- |
| **Build Pack** | `Dockerfile` | |
| **Port Exposes** | `80` | **Important**: Do not use 3000. Nginx serves on port 80. |
| **dockerfile Location** | `/Dockerfile` | |
| **Pre-deployment Command** | *Empty* | Clear any default PHP commands. |
| **Post-deployment Command** | *Empty* | Clear any default PHP commands. |
| **Environment Variables** | `FIREBASE_OPTIONS_BASE64` | Set this in the "Environment Variables" tab. Check **"Build Variable"**. |
