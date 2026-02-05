#set page(
  paper: "us-letter",
  margin: (
    top: 0.5in,
    bottom: 0.5in,
    left: 0.5in,
    right: 0.5in,
  ),
)

#set text(
  font: "Arial",
  size: 11pt,
  lang: "en",
  ligatures: false,
)

#show link: set text(rgb("#26428b"))
#show link: underline


#align(center)[
  #pad(top: 0pt, bottom: 0pt, [#text(16pt)[*Elijah McMorris*]])

  #link("mailto:NexVeridian@gmail.com") | Seattle, WA | 425-236-8715 | #link(
    "https://calendly.com/nexveridian/main",
  )[Schedule a Meeting]

  #link("https://git.nexveridian.com/NexVeridian")[Git.Nexv.dev] | #link(
    "https://github.com/NexVeridian",
  )[GitHub.com/NexVeridian] | #link("https://nexv.dev")[Nexv.dev] | #link(
    "https://linkedin.com/in/NexVeridian",
  )[LinkedIn.com/in/NexVeridian]
]


#set par(
  // spacing: 0.65em,
  spacing: 1em,
)
#set list(marker: [#h(0.5em)#text(size: 10pt)[◆]#h(0.5em)], indent: 1em)


*EDUCATION*
#line(length: 100%, stroke: 1pt)

*Master of Science, Computer Science* #h(1fr) Aug 2025 - Expected By Dec 2028

#h(1em) The University of Texas at Austin, Austin, TX (Remote), GPA 3.85

*Bachelor of Applied Science, Software Development* #h(1fr) Jun 2024

#h(1em) Lake Washington Institute of Technology, Kirkland, WA, GPA 3.57


#pad(top: 1em, bottom: 0em, [
  *OPEN SOURCE*
])
#line(length: 100%, stroke: 1pt)

#link(
  "https://github.com/jupyterlab/jupyterlab/issues?q=state%3Aclosed%20is%3Apr%20author%3Anexveridian%20is%3Amerged",
)[
  *JupyterLab*] | A web IDE for notebooks, code, and data science
- #link("https://github.com/jupyterlab/jupyterlab/pull/16341")[
    [\#16341]] Adds a button that finds and shuts down kernels that are not attached to an open
  notebook
- #link("https://github.com/jupyterlab/jupyterlab/pull/16265")[
    [\#16265]] Add a checkbox and a setting to skip showing the kernel restart dialog box when
  checked
- #link("https://github.com/jupyterlab/jupyterlab/pull/16208")[
    [\#16208]] Fix to correctly clear the output area of a cell in the notebook

#link(
  "https://github.com/loco-rs/loco/issues?q=is%3Apr%20author%3Anexveridian%20is%3Amerged",
)[
  *Loco.rs*] | A Rust MVC web framework inspired by Rails
- #link("https://github.com/loco-rs/loco/pull/1093")[
    [\#1093]] Allows some tests to run in parallel by using different ports, decreasing test time by
  65-90%
- #link("https://github.com/loco-rs/loco/pull/1397")[
    [\#1397]] Add support for showing nested routes when listing registered controllers
- #link("https://github.com/loco-rs/loco/pull/1360")[
    [\#1360]] Adds support for return yaml responses from routes
- #link(
    "https://github.com/loco-rs/loco/issues?q=is%3Apr%20author%3Anexveridian%20is%3Amerged",
  )[
    +15 more PRs]

#link("https://github.com/loco-rs/loco-openapi-Initializer")[
  *Loco OpenAPI*] | Created an official extension for #link(
  "https://github.com/loco-rs",
)[Loco.rs] adding OpenAPI integration
- Automatically generates the OpenAPI specification and documentation for the routes
- Serves the OpenAPI documentation using either Swagger-ui, Redoc, or Scalar

// #link("https://zed.dev/")[
//   *Zed.dev*] | A next-generation code editor designed for high-performance
// - #link("https://github.com/zed-industries/zed/pull/25606")[
//     [\#25606]] Fixes showing the max_tokens for each model in the assistant panel

#link(
  "https://github.com/search?q=author%3ANexVeridian+is%3Apublic+is%3Apr+is%3Amerged+-org%3Aloco-rs&type=pullrequests&p=1",
)[+15 documentation PRs and PRs with smaller changes across various projects]

#pad(top: 1em, bottom: 0em, [
  *PROJECTS*
])
#line(length: 100%, stroke: 1pt)
#link("https://ark.nexveridian.com/ARK/ARKK")[
  *Ark.Nexv.dev*] | #link("https://api.nexveridian.com/")[
  *Api.Nexv.dev*] | *ETF Holding Tracker* | Next.js, TypeScript, Rust | #link(
  "https://git.nexv.dev/NexVeridian/ark-invest-api-rust",
)[
  [GitHub]]
- Created and retrieves data from a REST API for the holdings of 25 ETFs and updated daily
- Visualizes it in an interactive chart, showing the ETF holdings over time
- Frontend is written in Next.js, using Tailwind, Chart.js, TanStack Table, Shadcn/ui
- Backend is written in Rust using Axum, Polars, and Redoc
*Wikidata To Surrealdb* | Rust #link(
  "https://git.nexv.dev/NexVeridian/wikidata-to-surrealdb",
)[
  [GitHub]]
- Created a tool for converting Wikidata BZ2 or JSON data dumps, to a SurrealDB database

#pad(top: 1em, bottom: 0em, [
  *SKILLS*
])
#line(length: 100%, stroke: 1pt)
*Languages*: Rust, TypeScript, Python, SQL, Nix, JavaScript, Java

*Developer Tools*: Docker, Git, JJ, GitHub, SSH, Cloudflare, AWS, Azure, VPS, Docker Compose

*Libraries*: MySQL, Postgres, Traefik, Nginx, Axum, Django, Flask, OpenAPI, Pandas, Numpy, Spark,
Polars, CI/CD, GitHub Actions

*Certifications*: Microsoft Office Specialist: Excel Associate - MOS Exam 77-727
#link(
  "https://www.credly.com/badges/8facfa32-3a3d-46bf-9e68-f1caad0f7801/public_url",
)[[Credly]]
