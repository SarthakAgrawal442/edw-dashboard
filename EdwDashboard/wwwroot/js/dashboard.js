// ── Theme toggle ─────────────────────────────────────────────────
(function () {
  const btn = document.querySelector('[data-theme-toggle]');
  const html = document.documentElement;

  if (!btn) return;

  let theme = localStorage.getItem('theme') ||
    (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');

  html.setAttribute('data-theme', theme);
  btn.textContent = theme === 'dark' ? '☀️' : '🌙';

  btn.addEventListener('click', () => {
    theme = theme === 'dark' ? 'light' : 'dark';
    html.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
    btn.textContent = theme === 'dark' ? '☀️' : '🌙';
  });
})();


// ── Chart.js defaults ────────────────────────────────────────────
Chart.defaults.color = '#797876';
Chart.defaults.font.family = "'Inter', system-ui, sans-serif";
Chart.defaults.font.size = 12;


// ── Palette ──────────────────────────────────────────────────────
const PALETTE = [
  '#4f98a3', '#6daa45', '#e8af34', '#dd6974', '#a86fdf',
  '#fdab43', '#5591c7', '#d163a7', '#bb653b', '#3a9e8c'
];

const GRADE_COLORS = {
  A: '#6daa45',
  B: '#4f98a3',
  C: '#e8af34',
  D: '#fdab43',
  F: '#dd6974'
};

const SEM_ORDER = { Spring: 0, Summer: 1, Fall: 2 };


// ── Helpers ──────────────────────────────────────────────────────
async function fetchJSON(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error(`${url} → ${r.status}`);
  return r.json();
}

function animateNumber(el, target, decimals = 0, suffix = '') {
  const dur = 800;
  const startTime = performance.now();

  const step = (now) => {
    const p = Math.min((now - startTime) / dur, 1);
    const val = (p * target).toFixed(decimals);

    el.textContent = decimals === 0
      ? Number(val).toLocaleString() + suffix
      : Number(val).toFixed(decimals) + suffix;

    if (p < 1) requestAnimationFrame(step);
  };

  requestAnimationFrame(step);
}

function termLabel(row) {
  return `${row.year} ${row.semester}`;
}

function sortTerms(a, b) {
  const [yearA, semA] = a.split(' ');
  const [yearB, semB] = b.split(' ');

  if (Number(yearA) !== Number(yearB)) {
    return Number(yearA) - Number(yearB);
  }

  return (SEM_ORDER[semA] ?? 99) - (SEM_ORDER[semB] ?? 99);
}


// ── KPIs ─────────────────────────────────────────────────────────
async function loadKpis() {
  const kpi = await fetchJSON('/api/edw/kpis');

  animateNumber(document.getElementById('kpi-students'), kpi.totalStudents);
  animateNumber(document.getElementById('kpi-courses'), kpi.totalCourses);
  animateNumber(document.getElementById('kpi-enrollments'), kpi.totalEnrollments);
  animateNumber(document.getElementById('kpi-gpa'), kpi.overallAvgGpa, 2);
  animateNumber(document.getElementById('kpi-pass'), kpi.overallPassRatePct, 1, '%');
}


// ── Chart 1: GPA by Dept Over Time ───────────────────────────────
async function loadGpaChart() {
  const data = await fetchJSON('/api/edw/gpa-by-dept');

  const terms = [...new Set(data.map(termLabel))].sort(sortTerms);
  const depts = [...new Set(data.map(r => r.deptName))].sort();

  const datasets = depts.map((dept, i) => ({
    label: dept,
    data: terms.map(term => {
      const [year, semester] = term.split(' ');
      const row = data.find(r =>
        r.deptName === dept &&
        String(r.year) === year &&
        r.semester === semester
      );
      return row ? row.avgGpa : null;
    }),
    borderColor: PALETTE[i % PALETTE.length],
    backgroundColor: PALETTE[i % PALETTE.length] + '22',
    tension: 0.35,
    pointRadius: 3,
    fill: false,
    spanGaps: true
  }));

  new Chart(document.getElementById('gpaChart'), {
    type: 'line',
    data: { labels: terms, datasets },
    options: {
      responsive: true,
      maintainAspectRatio: true,
      plugins: {
        legend: { position: 'bottom' }
      },
      scales: {
        y: {
          min: 0,
          max: 4,
          title: { display: true, text: 'Avg GPA' },
          grid: { color: '#33323044' }
        },
        x: {
          ticks: { maxRotation: 45 },
          grid: { color: '#33323044' }
        }
      }
    }
  });
}


// ── Chart 2: Grade Distribution ──────────────────────────────────
async function loadGradeChart() {
  const data = await fetchJSON('/api/edw/grade-distribution');

  const depts = [...new Set(data.map(r => r.deptName))].sort();
  const grades = ['A', 'B', 'C', 'D', 'F'];

  const datasets = grades.map(grade => ({
    label: grade,
    data: depts.map(dept => {
      const row = data.find(r => r.deptName === dept && r.finalGrade === grade);
      return row ? row.gradePct : 0;
    }),
    backgroundColor: GRADE_COLORS[grade]
  }));

  new Chart(document.getElementById('gradeChart'), {
    type: 'bar',
    data: { labels: depts, datasets },
    options: {
      responsive: true,
      maintainAspectRatio: true,
      plugins: {
        legend: { position: 'bottom' }
      },
      scales: {
        x: {
          stacked: true,
          ticks: { maxRotation: 20 },
          grid: { color: '#33323044' }
        },
        y: {
          stacked: true,
          min: 0,
          max: 100,
          title: { display: true, text: '% Students' },
          grid: { color: '#33323044' }
        }
      }
    }
  });
}


// ── Chart 3: Enrollment by Program per Semester ──────────────────
async function loadEnrollChart() {
  const data = await fetchJSON('/api/edw/enrollment');

  const terms = [...new Set(data.map(termLabel))].sort(sortTerms);
  const programs = [...new Set(data.map(r => r.program))].sort();

  const datasets = programs.map((program, i) => ({
    label: program,
    data: terms.map(term => {
      const [year, semester] = term.split(' ');
      const row = data.find(r =>
        r.program === program &&
        String(r.year) === year &&
        r.semester === semester
      );
      return row ? row.enrollmentCount : 0;
    }),
    backgroundColor: PALETTE[i % PALETTE.length]
  }));

  new Chart(document.getElementById('enrollChart'), {
    type: 'bar',
    data: { labels: terms, datasets },
    options: {
      responsive: true,
      maintainAspectRatio: true,
      plugins: {
        legend: { position: 'bottom' }
      },
      scales: {
        x: {
          stacked: true,
          ticks: { maxRotation: 45 },
          grid: { color: '#33323044' }
        },
        y: {
          stacked: true,
          title: { display: true, text: 'Enrollments' },
          grid: { color: '#33323044' }
        }
      }
    }
  });
}


// ── Chart 4: Pass Rate by Course ─────────────────────────────────
async function loadPassChart() {
  const data = await fetchJSON('/api/edw/pass-rate');

  const top20 = data.slice(0, 20);
  const labels = top20.map(r => `${r.courseName} (${r.instructorName})`);
  const values = top20.map(r => r.passRatePct);
  const colors = values.map(v => v >= 75 ? '#6daa45' : v >= 50 ? '#e8af34' : '#dd6974');

  new Chart(document.getElementById('passChart'), {
    type: 'bar',
    data: {
      labels,
      datasets: [
        {
          label: 'Pass Rate %',
          data: values,
          backgroundColor: colors
        }
      ]
    },
    options: {
      indexAxis: 'y',
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false }
      },
      scales: {
        x: {
          min: 0,
          max: 100,
          title: { display: true, text: 'Pass Rate %' },
          grid: { color: '#33323044' }
        },
        y: {
          ticks: { font: { size: 11 } },
          grid: { color: '#33323044' }
        }
      }
    }
  });

  document.getElementById('passChart').style.maxHeight = '520px';
}


// ── Boot ─────────────────────────────────────────────────────────
Promise.all([
  loadKpis(),
  loadGpaChart(),
  loadGradeChart(),
  loadEnrollChart(),
  loadPassChart()
]).catch(err => console.error('Dashboard error:', err));