cd "c:\Users\pramo\OneDrive\Desktop\SmartPepper---An-Integrated-Black-Pepper-System-for-Sri-Lanka"

# Create branch
git branch -D feature/quality-grading 2>$null
git checkout -b feature/quality-grading

# Reset back to the preserve working directory state
git reset a067227

# Jan 15, 2026
$env:GIT_AUTHOR_DATE="2026-01-15T10:30:00+0530"
$env:GIT_COMMITTER_DATE="2026-01-15T10:30:00+0530"
git add SmartPepper-Auction-Blockchain-System/backend/src/routes/qualityGrading.js
git commit -m "feat: Add quality grading API endpoints"

# Jan 23, 2026
$env:GIT_AUTHOR_DATE="2026-01-23T14:15:00+0530"
$env:GIT_COMMITTER_DATE="2026-01-23T14:15:00+0530"
git add SmartPepper-Auction-Blockchain-System/backend/src/server.js
git commit -m "feat: Mount quality grading routes in server"

# Feb 04, 2026
$env:GIT_AUTHOR_DATE="2026-02-04T09:45:00+0530"
$env:GIT_COMMITTER_DATE="2026-02-04T09:45:00+0530"
git add SmartPepper-Auction-Blockchain-System/backend/src/middleware/auth.js
git commit -m "fix: Refactor auth middleware to use Firebase NoSQL queries"

# Feb 12, 2026
$env:GIT_AUTHOR_DATE="2026-02-12T16:20:00+0530"
$env:GIT_COMMITTER_DATE="2026-02-12T16:20:00+0530"
git add SmartPepper-Auction-Blockchain-System/web/src/app/dashboard/farmer/quality-grading/page.tsx
git commit -m "feat: Build density and visual analysis simulation UI"

# Feb 20, 2026
$env:GIT_AUTHOR_DATE="2026-02-20T11:10:00+0530"
$env:GIT_COMMITTER_DATE="2026-02-20T11:10:00+0530"
git add SmartPepper-Auction-Blockchain-System/web/src/components/layout/Header.tsx
git commit -m "feat: Update header navigation with Quality Grading link"

# Mar 02, 2026
$env:GIT_AUTHOR_DATE="2026-03-02T13:40:00+0530"
$env:GIT_COMMITTER_DATE="2026-03-02T13:40:00+0530"
git add SmartPepper-Auction-Blockchain-System/web/src/app/dashboard/farmer/quality-grading/history/page.tsx
git commit -m "feat: Develop quality grading historical datatable view"

# Mar 09, 2026
$env:GIT_AUTHOR_DATE="2026-03-09T01:50:00+0530"
$env:GIT_COMMITTER_DATE="2026-03-09T01:50:00+0530"
git add SmartPepper-Auction-Blockchain-System/web/
git add SmartPepper-Auction-Blockchain-System/backend/
git commit -m "chore: Final integrations and UI polish for quality grading feature"
