using UnityEngine;
using TMPro;
using UnityEngine.UI;

namespace UI.MainMenu.Credits {
    public class CreditsItem : MonoBehaviour {
        [SerializeField] private TextMeshProUGUI nameText;
        [SerializeField] private TextMeshProUGUI ownerText;
        [SerializeField] private Button button;

        private string linkUrl;

        public void Initialize(CreditItem data) {
            // "Skyscraper" (bold)
            if (nameText != null) nameText.text = $"<b>{data.name}</b>";
            
            // "ManySince910"
            if (ownerText != null) ownerText.text = data.owner;
            
            linkUrl = data.link;

            if (button != null) {
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(OnClicked);
            }
        }

        private void OnClicked() {
            if (!string.IsNullOrEmpty(linkUrl)) {
                Debug.Log($"[CreditsItem] Opening URL: {linkUrl}");
                Application.OpenURL(linkUrl);
            }
        }
    }
}
