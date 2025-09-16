import type { Course } from '../types';
import { Fragment } from 'react';
const GettingStarted: Course = {
  slug: 'getting-started',
  title: 'Getting Started with the AI Tutor',
  level: 'Beginner',
  estMinutes: 25,
  description: 'From first prompt to first shipped result, with near‑zero cost.',
  lessons: [
    { slug: 'setup', title: 'Setup & First Run', durationMin: 10, summary: 'Local dev, health check, and your first prompt.',
      content: (
        <Fragment>
          <p><strong>Goal:</strong> have the app running and streaming.</p>
          <ol>
            <li>Open the app and confirm <code>/api/health</code> returns 200.</li>
            <li>Send a short prompt and watch SSE tokens arrive.</li>
            <li>Export the session to markdown.</li>
          </ol>
        </Fragment>
      )
    },
    { slug: 'ship', title: 'From Draft to Ship', durationMin: 15, summary: 'Short loop: draft → review → ship, with token caps.',
      content: (
        <Fragment>
          <p>Keep replies short. Prefer structured prompts. Use export to capture final output.</p>
          <ul>
            <li>Ask for bullets and headings.</li>
            <li>Ship small slices; avoid long rambles.</li>
          </ul>
        </Fragment>
      )
    }
  ],
};
export default GettingStarted;
