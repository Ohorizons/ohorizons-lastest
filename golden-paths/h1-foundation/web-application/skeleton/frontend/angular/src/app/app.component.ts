import { Component } from '@angular/core';

@Component({
  selector: 'app-root',
  standalone: true,
  template: `
    <div style="max-width: 800px; margin: 0 auto; padding: 2rem">
      <h1>${{ values.appName }}</h1>
      <p>Welcome to your new application.</p>
      <button (click)="count = count + 1">Count: {{ count }}</button>
    </div>
  `,
})
export class AppComponent {
  count = 0;
}
