using System.Collections.Generic;

namespace UI.MainMenu.Credits {
    [System.Serializable]
    public class CreditsRoot {
        public AssetsData assets;
    }

    [System.Serializable]
    public class AssetsData {
        public List<CreditItem> models_3d;
        public List<CreditItem> sound_effects;
        public List<CreditItem> music;
    }

    [System.Serializable]
    public class CreditItem {
        public string owner;
        public string name;
        public string link;
    }
}
