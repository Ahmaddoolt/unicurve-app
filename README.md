# 🎓 UniCurve - Student Success Platform

<p align="center">
  <img src="https://github.com/user-attachments/assets/70d17b89-e727-4999-a4a5-22dc2c53e0b5" alt="UniCurve App Banner" width="600"/>
</p>

> A comprehensive student success platform designed to empower university students by helping them navigate their academic journey, optimize course planning, and visualize their progress.

This project is more than just a course planner; it's a full-featured tool built to handle complex academic rules and provide students with the clearest path to graduation. It features a student-facing mobile app and a dedicated admin interface for university management.

---

## ✨ Core Features

UniCurve is packed with powerful features designed for both students and administrators.

### 🧑‍🎓 For Students:

*   **Optimal Timetable Generation:**
    *   Leverages a **custom priority-based scheduling algorithm** to automatically generate the top three best possible timetables based on subject prerequisites and real-time dependencies.
*   **Dynamic Subject Dependency Tree:**
    *   An interactive, visual graph that clearly shows which subjects unlock others, helping students plan multiple semesters ahead.
*   **Comprehensive GPA & Progress Tools:**
    *   **GPA Calculator:** Instantly calculate term and cumulative GPA.
    *   **GPA Improvement Plan:** Receive intelligent suggestions on what grades are needed to reach a target GPA.
    *   **Progress Visualizer:** Track completed credits, remaining subjects, and overall academic standing at a glance.
*   **Doctor & Subject Information:**
    *   Browse detailed information about each subject and see which professors are teaching it.

### 🔑 For Admins:

*   **Secure Admin Panel:** A separate, secure interface for university administrators to manage the core academic data.
*   **Full CRUD Functionality:** Admins can easily Create, Read, Update, and Delete subjects, timetables, and professor information, ensuring the app's data is always up-to-date.

---

## 📸 Screenshots

<p align="center">
  <img src="[LINK TO SCREENSHOT 1: Dependency Tree]" alt="Dependency Tree" width="250"/>
  <img src="[LINK TO SCREENSHOT 2: Timetable Generator]" alt="Timetable Generator" width="250"/>
  <img src="[LINK TO SCREENSHOT 3: GPA Planner]" alt="GPA Planner" width="250"/>
</p>

---

## 🛠️ Technology Stack & Architecture

This project was built with a modern, scalable, and maintainable tech stack.

*   **Frontend:** **Flutter** & **Dart**
*   **Backend & Database:** **Supabase** (PostgreSQL, Authentication, Storage)
*   **Architecture:** **Model-View-Controller (MVC)** to ensure a clean separation of concerns.
*   **State Management:** **Riverpod** for a reactive and robust state management solution.
*   **Translation:** **GetX** for seamless localization support.
*   **Local Storage:** **SharedPreferences** for caching user preferences.

---

## 🧠 The Core Algorithm

The heart of UniCurve is a custom, heuristic-based scheduling algorithm designed to solve the complex problem of timetable creation. It intelligently finds the best schedules by following these steps:

1.  **Priority Scoring:** It first calculates a "priority weight" for every available subject based on how many future courses it unlocks. This ensures that critical "gateway" subjects are prioritized.

2.  **Ranked List Generation:** All available subjects are sorted into a list from highest to lowest priority.

3.  **Iterative Timetable Construction:** The algorithm iterates through the prioritized list, attempting to add one subject at a time to a new timetable.

4.  **Intelligent Conflict Resolution (The Core Logic):** When adding a new subject (e.g., `Numerical Analysis`) results in a time conflict with an already-placed subject (e.g., `Math 2`):
    *   **It doesn't fail.** Instead, it first attempts to resolve the conflict by trying all other available sections or categories for `Math 2`.
    *   If no section of `Math 2` works, the algorithm **backtracks** further. It will then try to change the section of the *previous* subject (`Programming 2`) to free up a new time slot that could accommodate both `Math 2` and `Numerical Analysis`.
    *   This backtracking and permutation process allows the system to explore multiple combinations to find a valid, conflict-free schedule.

5.  **Presenting Top 3 Options:** The entire process is run to generate the **top three most optimal, conflict-free timetable options**, giving the student the power to choose the best schedule for their needs.
