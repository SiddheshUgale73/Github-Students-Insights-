# 🎨 Dashboard Design Blueprint: Mentor Monitoring Portal

This technical documentation outlines the professional dashboard layout engineered to help academic mentors supervise student project health, teamwork equity, development pacing, and well-being.

---

## 🏗️ 1. Visual Hierarchy & Grid Layout

The interface is structured using a **2-Column Responsive F-Shape Grid**, separating batch-level summaries from active watchlists.

```
+----------------------------------------------------------------------------------+
|  🎓 GitHub Projects Insights: Mentor Evaluation Center                          |
+----------------------------------------------------------------------------------+
|  [Slicers: Programming Language | Team Size | Health Grade | Project Search]     |
+----------------------------------------------------------------------------------+
|  +----------------------------------------------------------------------------+  |
|  | SECTION 1: 📈 Project Health Score (AI-Clustered Performance Tiers)        |  |
|  +----------------------------------------------------------------------------+  |
|  +-------------------------------------+ +------------------------------------+  |
|  | SECTION 2: 🚨 Risk Watchlist        | | SECTION 3: 🤝 Collaboration Index  |  |
|  | (Critical Teams Needing Review)     | | (Anti-Free-Rider Matrix & Velocity)|  |
|  +-------------------------------------+ +------------------------------------+  |
|  +-------------------------------------+ +------------------------------------+  |
|  | SECTION 4: 🔥 Burnout Analysis      | | SECTION 5: 🏆 Project Ranking      |  |
|  | (Isolation Forest Anomaly Map)      | | (Batch Performance Leaderboard)   |  |
|  +-------------------------------------+ +------------------------------------+  |
+----------------------------------------------------------------------------------+
```

---

## 📊 2. Deep-Dive Section Specifications

### Section 1: 📈 Project Health Score
* **Objective**: Provides an immediate top-level overview of the entire class performance distribution using the **K-Means Clustering AI model**.
* **Visual Components**:
  * **AI Class Distribution (Donut Chart)**: Visualizes the proportion of projects assigned to Grades A, B, C, and D/F.
  * **Unified Progress Indicator (Area Chart)**: Displays overall commit velocity trends across different grade cohorts over the semester timeline.
* **Snowflake Source Table/View**: `DASHBOARD_REPO_SUMMARY` & `DASHBOARD_COMMIT_TRENDS`
* **Color Code Scheme**:
  * `Grade A (Excellent Progress)` ➔ `#10B981` (Emerald Green)
  * `Grade B (Good Progress)` ➔ `#3B82F6` (Ocean Blue)
  * `Grade C (At Risk / Slow)` ➔ `#F59E0B` (Amber)
  * `Grade D/F (Stalled / Critical)` ➔ `#EF4444` (Crimson)

### Section 2: 🚨 Risk Watchlist
* **Objective**: Active triage zone alerting mentors to projects that have stalled, had communication breakdowns, or exhibit high bottleneck risks.
* **Visual Components**:
  * **Immediate Intervention List (Data Grid)**: Automatically filters and flags projects with over 14 days of absolute inactivity.
  * **PR Review Pipeline (Gauge Card)**: Tracks the average time (in days) taken to review and merge Pull Requests.
* **Snowflake Source Table/View**: `DASHBOARD_PR_INSIGHTS` (calculating `DATEDIFF` on PR cycles).

### Section 3: 🤝 Collaboration Index
* **Objective**: Audits work distribution equity among group members to prevent **free-riding** and assess individual effort fairly.
* **Visual Components**:
  * **Team Contribution Share (100% Stacked Bar Chart)**: Visualizes the contribution percentage of commits authored by each student per repository.
  * **Leader Dependence Index (Card Visual)**: Displays the ratio of the top contributor's commits to the total project commits. If this number is **>70%**, a red alert is triggered.
* **Snowflake Source Table/View**: `DASHBOARD_TEAM_DYNAMICS` (custom view aggregates max student share).

### Section 4: 🔥 Burnout Analysis
* **Objective**: Mentors student welfare by highlighting irregular, overnight, or weekend work patterns that indicate high stress or burnout.
* **Visual Components**:
  * **Fatigue Anomaly Plot (Scatter Chart)**: Plots the *Weekend Commit Ratio* (X-axis) against the *Late Night Commit Ratio* (Y-axis).
  * **High-Risk Watchlist (Alert Table)**: Lists students classified as outliers by the **Isolation Forest Anomaly Detection model** (`needs_mentor_attention` = `True`).
* **Snowflake Source Table/View**: `DASHBOARD_STUDENT_WELLBEING` (aggregates temporal commit habits).

### Section 5: 🏆 Project Ranking
* **Objective**: An interactive, searchable leaderboard designed for final defenses, enabling quick search, filtering by language, and grade evaluation.
* **Visual Components**:
  * **Interactive Batch Leaderboard (Matrix Grid)**: Lists all projects sorted by activity levels, commit velocity, stargazer scores, and assigned AI grades.
* **Snowflake Source Table/View**: `DASHBOARD_REPO_SUMMARY` (consolidates developer specifications).

---

## 🔄 3. Interactive Cross-Filtering Mechanics

To deliver a premium dashboard experience, the following interactive linkages should be activated in the visual settings:

1. **Grade Filter**: Clicking on the **Grade D/F** segment in the Section 1 Donut Chart automatically filters the Section 5 Leaderboard to isolate failing projects.
2. **Burnout Interaction**: Clicking on any anomaly dot in the Section 4 Scatter Plot immediately cross-filters the database to show the specific student's repository and commit velocity.
3. **Repository Search**: Typing a project name in the global search bar focuses all charts solely on that team's collaboration dynamics, burnout profiles, and pacing metrics.
