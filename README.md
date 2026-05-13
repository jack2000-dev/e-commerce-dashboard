# building-workshop-template

![HyperbolicTimeChamber_Dragonball](/img/hyperbolic_time_chamber.png)

`building-workshop-template` is a reusable learn-by-building workshop for data
roles. It helps a learner work with an AI mentor to choose a project, assess
their current level, build the project in milestones, get hints when stuck, and
finish with structured feedback.

Target roles:

- Data engineer
- Analytics engineer
- Technical data analyst

The default stack is `uv`, Python, SQL, DuckDB or Postgres, dbt, pytest, and
Pandas or Polars, but the AI mentor should always ask before assuming the
stack.

## What This Template Does

This is not a fixed tutorial. It is a scaffold for generating a custom project
from the learner's goals.

Example learner prompt:

```text
I want to learn by building a project for a data engineer or analytics engineer
role. I have basic skills, I use uv, SQL, Python, and I want to build a solid
project that I can explain to an interviewer.
```

The AI mentor should respond by interviewing the learner, running a before
assessment, generating a project, guiding the build, and scoring the final
submission.

## How To Use

1. Start a new AI conversation.
2. Attach or reference `AGENT.md` and `start/SKILL.md`.
3. Ask the AI mentor to begin the workshop.
4. Fill out `start/PROJECT_INTAKE.md`.
5. Complete the before assessment.
6. Let the AI mentor generate `problem/project-brief.md`.
7. Build through the milestones in `problem/milestones.md`.
8. Ask for hints or solutions only when needed.
9. Complete the after assessment.
10. Submit the project for scoring with `score/score.md`.

## Recommended First Prompt

```text
Use AGENT.md and start/SKILL.md. Interview me, assess my current level, and
generate a custom learn-by-building project for my data role goals.
```

### Use GitHub's **Use this template** button, then clone the new repo

## Folder Structure

```text
.
├── AGENT.md
├── README.md
├── start/
│   ├── AGENT.md
│   ├── SKILL.md
│   └── PROJECT_INTAKE.md
├── before-assessment/
│   ├── README.md
│   ├── assessment.md
│   └── rubric.md
├── problem/
│   ├── README.md
│   ├── project-brief.md
│   ├── assignment.md
│   ├── milestones.md
│   ├── generated-workspace.md
│   └── submission.md
├── solution/
│   ├── README.md
│   └── solution-playbook.md
├── learning-material/
│   ├── README.md
│   ├── data-engineer.md
│   ├── analytics-engineer.md
│   └── technical-data-analyst.md
├── after-assessment/
│   ├── README.md
│   └── assessment.md
└── score/
    ├── score.md
    └── rubric.md
```

## Workshop Flow

### 1. Start

Use `start/PROJECT_INTAKE.md` to capture the learner's target role, level,
stack, preferences, time budget, and interview goals.

### 2. Before Assessment

Use `before-assessment/assessment.md` to establish a baseline. The goal is to
measure starting skill, not to fail the learner.

### 3. Problem

The AI mentor fills in `problem/project-brief.md`, `problem/assignment.md`, and
`problem/milestones.md` based on the intake and assessment.

### 4. Solution

Use `solution/solution-playbook.md` for hints, partial solutions, and full
solutions only when needed.

### 5. Learning Material

Use the relevant role file in `learning-material/` to support the project. Do
not turn it into a long lecture. Tie concepts to the current milestone.

### 6. After Assessment

Use `after-assessment/assessment.md` after the project is complete. Compare it
with the before assessment to measure progression.

### 7. Score

Use `score/score.md` and `score/rubric.md` to score the final project,
explanation, tests, documentation, and interview readiness.

## Mentor Behavior

The AI mentor should be adaptive:

- Ask questions before generating the project.
- Recommend a stack but confirm preferences.
- Give hints before full solutions.
- Review every milestone.
- Ask the learner to explain decisions.
- Score both the project and the learner's ability to explain it.

## What A Finished Project Should Include

- Reproducible setup
- Working data workflow
- SQL and Python logic
- Data quality checks
- Tests or validation queries
- Project README
- Architecture or data flow explanation
- Interview talking points
- Known limitations and next steps

## Customization

To adapt this template:

- Add role-specific learning material.
- Add project examples in `problem/`.
- Add stricter rubrics in `score/`.
- Add more assessment questions for your target interview style.
- Add local setup instructions for your preferred data tools.

## License

The files in this repository are licensed under the [Creative Commons Attribution-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-sa/4.0/).
