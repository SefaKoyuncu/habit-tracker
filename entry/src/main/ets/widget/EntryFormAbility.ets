import { FormExtensionAbility, formBindingData, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { DatabaseService } from '../core/services/DatabaseService';

export default class EntryFormAbility extends FormExtensionAbility {
  async onAddForm(want: Want) {
    // 1. Init Database
    await DatabaseService.init(this.context);

    // 2. Fetch all rituals to calculate progress
    let allRituals = [];
    for (let i = 1; i <= 3; i++) {
      allRituals.push(...await DatabaseService.instance.loadRituals(i));
    }

    const completed = allRituals.filter(r => r.completed).length;
    const total = allRituals.length;
    const progress = total > 0 ? Math.round((completed / total) * 100) : 0;
    const nextRitual = allRituals.find(r => !r.completed)?.title || 'All Done! 🎉';

    const formData = {
      'title': 'Habit Tracker',
      'progress': progress + '%',
      'nextRitual': nextRitual
    };
    return formBindingData.createFormBindingData(formData);
  }

  onUpdateForm(formId: string) {
    // Manual updates could be triggered here via postCardAction
  }

  onRemoveForm(formId: string) {
  }
}
