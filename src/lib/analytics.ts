export type AnalyticsProps = Record<string, string | number | boolean | null | undefined>;
export const track = (name: string, props: AnalyticsProps = {}) => {
  console.debug('[event]', name, props);
};


