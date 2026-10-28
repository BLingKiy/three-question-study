import preferences from '@ohos.data.preferences';

const PREFERENCES_NAME = 'ThreeQuestionStudyPrefs';

export class PreferencesService {
  private prefs: preferences.Preferences | null = null;
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async initialize(): Promise<void> {
    try {
      this.prefs = await preferences.getPreferences(this.context, PREFERENCES_NAME);
      console.info('[PreferencesService] Preferences initialized successfully');
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : String(err);
      console.error('[PreferencesService] Failed to initialize:', errMsg);
      throw new Error('Preferences初始化失败: ' + errMsg);
    }
  }

  private getPrefs(): preferences.Preferences {
    if (!this.prefs) {
      throw new Error('Preferences not initialized. Call initialize() first.');
    }
    return this.prefs;
  }

  // API Key management
  async setApiKey(apiKey: string): Promise<void> {
    await this.getPrefs().put('api_key', apiKey);
    await this.getPrefs().flush();
  }

  async getApiKey(): Promise<string> {
    return await this.getPrefs().get('api_key', '') as string;
  }

  async hasApiKey(): Promise<boolean> {
    const key = await this.getApiKey();
    return key.length > 0;
  }

  // Theme settings
  async setTheme(theme: 'light' | 'dark' | 'auto'): Promise<void> {
    await this.getPrefs().put('theme', theme);
    await this.getPrefs().flush();
  }

  async getTheme(): Promise<'light' | 'dark' | 'auto'> {
    return await this.getPrefs().get('theme', 'auto') as 'light' | 'dark' | 'auto';
  }

  // User settings
  async setUserName(name: string): Promise<void> {
    await this.getPrefs().put('user_name', name);
    await this.getPrefs().flush();
  }

  async getUserName(): Promise<string> {
    return await this.getPrefs().get('user_name', '学习者') as string;
  }

  // Statistics
  async incrementTotalCourses(): Promise<void> {
    const current = await this.getTotalCourses();
    await this.getPrefs().put('total_courses', current + 1);
    await this.getPrefs().flush();
  }

  async getTotalCourses(): Promise<number> {
    return await this.getPrefs().get('total_courses', 0) as number;
  }

  async incrementTotalAssessments(): Promise<void> {
    const current = await this.getTotalAssessments();
    await this.getPrefs().put('total_assessments', current + 1);
    await this.getPrefs().flush();
  }

  async getTotalAssessments(): Promise<number> {
    return await this.getPrefs().get('total_assessments', 0) as number;
  }

  async updateAverageScore(score: number): Promise<void> {
    const total = await this.getTotalAssessments();
    const currentAvg = await this.getAverageScore();
    const newAvg = total > 1 ? (currentAvg * (total - 1) + score) / total : score;
    await this.getPrefs().put('average_score', newAvg);
    await this.getPrefs().flush();
  }

  async getAverageScore(): Promise<number> {
    return await this.getPrefs().get('average_score', 0) as number;
  }

  // Onboarding
  async setOnboardingComplete(complete: boolean): Promise<void> {
    await this.getPrefs().put('onboarding_complete', complete);
    await this.getPrefs().flush();
  }

  async isOnboardingComplete(): Promise<boolean> {
    return await this.getPrefs().get('onboarding_complete', false) as boolean;
  }

  async setColorMode(mode: number): Promise<void> {
    await this.getPrefs().put('color_mode', mode);
    await this.getPrefs().flush();
  }

  async getColorMode(): Promise<number> {
    return await this.getPrefs().get('color_mode', -1) as number;
  }

  // Clear all preferences
  async clear(): Promise<void> {
    await this.getPrefs().clear();
    await this.getPrefs().flush();
  }
}
