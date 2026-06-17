import {
  createPlugin,
  createRoutableExtension,
} from '@backstage/core-plugin-api';
import { chatPageRouteRef } from './routes';

/**
 * The AI Chat plugin for Open Horizons.
 * Powered by Claude SDK + MCP tools.
 */
export const aiChatPlugin = createPlugin({
  id: 'ai-chat',
  routes: {
    root: chatPageRouteRef,
  },
});

/**
 * Routable extension — the main AI Chat page.
 */
export const AiChatPage = aiChatPlugin.provide(
  createRoutableExtension({
    name: 'AiChatPage',
    component: () =>
      import('./components/ChatPage/ChatPage').then(
        m => m.default as unknown as (props: any) => JSX.Element | null,
      ),
    mountPoint: chatPageRouteRef,
  }),
);
