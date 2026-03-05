# GitHub and Git: A Collaborative Workflow Guide

GitHub is a collaborative coding platform that allows users to store their files in the cloud. Files are organized into **repositories**, which can be public or private depending on access requirements. GitHub is built on top of an application called **Git**, a powerful version control system.

---

## 1. Core Concepts

### What is Git?
Git is a tool for programmers to create "snapshots" or "checkpoints" in their code. It allows you to **commit** changes at any point. If you make a significant mistake, you can revert your code to a previous commit, ensuring your work is always protected. This is particularly helpful when adding new features; if they fail, you can easily restore a known working state.

### Branching
Branching is the primary way developers collaborate without interfering with each other's work.
*   **Main Branch**: By default, everyone starts on the `main` branch. 
*   **Feature Branches**: It is best practice to create new branches for specific tasks. 
*   **Isolation**: Commits made on one branch do not affect others initially. Switching branches instantly changes the files in your project folder to match the state of that specific branch.

### Merging
Merging combines the histories of two branches. Typically, feature branches are merged back into the `main` branch once work is complete. Git intelligently handles most merges. However, if two commits change the same section of code, a **merge conflict** occurs, requiring a manual decision on which version to keep.

---

## 2. Getting Started

### Prerequisites
Ensure Git is installed on your system. Open a terminal (CMD or PowerShell) and type:
```bash
git --version
```
If Git is not found, download it from [git-scm.com/install/windows](https://git-scm.com/install/windows).

### Setup and Cloning
1.  **Create a Project Folder**: Create a folder on your computer where you will do your work.
2.  **Open Terminal**: Open a CMD or PowerShell terminal inside that folder.
3.  **Clone the Repository**:
    ```bash
    git clone [repository-url]
    ```
    *Replace `[repository-url]` with the link to the project repository.*
4.  **Enter the Repository**:
    ```bash
    cd [repository-folder-name]
    ```

> [!NOTE]
> Your local folder is independent of the GitHub cloud repository. Changes you make locally will not reflect on GitHub until you explicitly use Git commands to "push" them.

---

## 3. Workflow: Viewing Files Only
Use this workflow if you primarily need to stay up to date with others' work without contributing changes yourself.

### Keep Local Files Updated
1.  **Navigate to Main**: `git switch main`
2.  **Fetch Updates**: `git fetch origin`
3.  **Check Status**: `git status` (This will tell you if your local branch is behind the cloud branch `origin/main`).

### Downloading Changes
If you haven't made any local changes:
1.  **Pull Updates**: `git pull`

If you *have* made changes but want to save them before updating:
1.  **Create a Save-Point**: `git switch -c [branch-name]`
2.  **Stage Files**: `git add .`
3.  **Commit**: `git commit -m "Saved my changes locally"`
4.  **Return to Main**: `git switch main`
5.  **Pull**: `git pull`

---

## 4. Workflow: Editing and Contributing
Use this workflow when you want to modify files and share those changes with the team.

### Step 1: Prep the Main Branch
Before starting new work, ensure your `main` branch is current:
```bash
git switch main
git fetch origin
git pull
```

### Step 2: Create a Feature Branch
Always work on a separate branch to keep the `main` code stable:
```bash
git switch -c [feature-name]
```

### Step 3: Make and Save Changes
Modify your files as normal. When you reach a milestone, create a checkpoint:
```bash
git add .
git commit -m "Brief description of what I changed"
```

### Step 4: Share with GitHub
Upload your local branch to the cloud:
*   **First time pushing this branch**: `git push -u origin [feature-name]`
*   **Subsequent pushes**: `git push`

### Step 5: Merge to Main
1.  Go to the repository on **GitHub.com**.
2.  Open the **Pull Requests** tab.
3.  Create a **New Pull Request** for your branch.
4.  Once reviewed and confirmed (no conflicts), click **Merge**.

---

## 5. Essential Command Cheat Sheet

| Command | Description |
| :--- | :--- |
| `git clone [url]` | Downloads the project to your computer. |
| `git branch` | Lists all branches (Green indicates current). |
| `git status` | Shows current branch and modified files. |
| `git switch [name]` | Switches to an existing branch. |
| `git switch -c [name]` | Creates a new branch and switches to it. |
| `git add .` | Stages all current changes for a commit. |
| `git commit -m "msg"` | Saves a local checkpoint with a message. |
| `git push` | Uploads local commits to GitHub. |
| `git pull` | Downloads and merges cloud changes into your local branch. |
| `git fetch origin` | Updates your local knowledge of cloud changes. |
| `git reset --hard` | **Warning**: Force-reverts all local changes since last commit. |

---

> [!IMPORTANT]
> - Always check your current branch with `git branch`.
> - Avoid working directly on `main` in collaborative environments.
> - Ensure you `push` your changes if you want others to see them.
