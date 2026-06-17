import { ReactNode } from 'react';
import { Content, Header, Page } from '@backstage/core-components';

type StandardPageProps = {
  title: string;
  subtitle?: string;
  themeId?: string;
  children: ReactNode;
};

export const StandardPage = ({
  title,
  subtitle,
  themeId = 'home',
  children,
}: StandardPageProps) => {
  return (
    <Page themeId={themeId}>
      <Header title={title} subtitle={subtitle} />
      <Content>{children}</Content>
    </Page>
  );
};
