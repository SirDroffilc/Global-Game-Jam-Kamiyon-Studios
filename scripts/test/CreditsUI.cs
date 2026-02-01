using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using TMPro;
using UI.MainMenu.Main;

namespace UI.MainMenu.Credits {
    public class CreditsUI : MonoBehaviour {
        [Header("Configuration")]
        [SerializeField] private TextAsset creditsJson;
        [SerializeField] private float scrollSpeed = 50f;
        // [SerializeField] private float resetPositionThreshold = 1500f; // Deprecated: Now calculated dynamically

        [Header("References")]
        [SerializeField] private GameObject creditsPanel;
        [SerializeField] private RectTransform contentParent;
        [SerializeField] private Button backButton;
        [SerializeField] private Button closePanelButton; // Optional full screen click?

        [Header("Prefabs")]
        [SerializeField] private GameObject headerPrefab;
        [SerializeField] private GameObject creditItemPrefab;

        public MainMenuUI mainMenuUI { get; set; }

        private bool isScrolling = false;
        private float initialY;
        private List<GameObject> spawnedObjects = new List<GameObject>();

        private void Awake() {
            backButton.onClick.AddListener(CloseCredits);
            if (closePanelButton != null) {
                closePanelButton.onClick.AddListener(CloseCredits);
            }

            initialY = contentParent.anchoredPosition.y;
        }

        private void Start() {
            ParseAndGenerateCredits();
        }

        private void Update() {
            if (!isScrolling) return;

            // Scroll Up
            contentParent.anchoredPosition += Vector2.up * scrollSpeed * Time.deltaTime;

            // Calculate dynamic threshold based on content height + screen buffer
            float dynamicThreshold = contentParent.rect.height + Screen.height;

            // Reset if we go too high
            if (contentParent.anchoredPosition.y > dynamicThreshold) {
                // Reset to below the screen for a smooth loop, or 0 to restart immediately
                // Using -Screen.height allows it to scroll in from the bottom again
                contentParent.anchoredPosition = new Vector2(contentParent.anchoredPosition.x, -Screen.height);
            }
        }

        public void ToggleCreditsUI(bool value) {
            creditsPanel.SetActive(value);
            isScrolling = value;

            if (value) {
                // Reset position when opening
                contentParent.anchoredPosition = new Vector2(contentParent.anchoredPosition.x, 0f); // Assuming 0 is start
            }
        }

        private void CloseCredits() {
            mainMenuUI?.ToggleMainMenuUI(true);
            ToggleCreditsUI(false);
        }

        private void ParseAndGenerateCredits() {
            if (creditsJson == null) {
                Debug.LogError("[CreditsUI] No JSON file assigned!");
                return;
            }

            CreditsRoot data = JsonUtility.FromJson<CreditsRoot>(creditsJson.text);
            if (data == null || data.assets == null) {
                Debug.LogError("[CreditsUI] Failed to parse JSON data.");
                return;
            }

            ClearExisting();

            // 1. 3D Models
            if (data.assets.models_3d != null && data.assets.models_3d.Count > 0) {
                CreateHeader("3D Models");
                foreach (var item in data.assets.models_3d) {
                    CreateItem(item);
                }
            }

            // 2. Sound Effects
            if (data.assets.sound_effects != null && data.assets.sound_effects.Count > 0) {
                CreateHeader("Sound Effects");
                foreach (var item in data.assets.sound_effects) {
                    CreateItem(item);
                }
            }

            // 3. Music
            if (data.assets.music != null && data.assets.music.Count > 0) {
                CreateHeader("Music");
                foreach (var item in data.assets.music) {
                    CreateItem(item);
                }
            }
            
            // Force layout rebuild so content size fitter updates (if present)
            LayoutRebuilder.ForceRebuildLayoutImmediate(contentParent);
        }

        private void ClearExisting() {
            foreach (var obj in spawnedObjects) {
                Destroy(obj);
            }
            spawnedObjects.Clear();
        }

        private void CreateHeader(string title) {
            if (headerPrefab == null) return;
            // Use 'false' to preserve the prefab's local RectTransform settings (size/scale)
            GameObject obj = Instantiate(headerPrefab, contentParent, false);
            spawnedObjects.Add(obj);

            TextMeshProUGUI tmp = obj.GetComponentInChildren<TextMeshProUGUI>();
            if (tmp != null) tmp.text = title;
        }

        private void CreateItem(CreditItem item) {
            if (creditItemPrefab == null) return;
            // Use 'false' to preserve the prefab's local RectTransform settings (size/scale)
            GameObject obj = Instantiate(creditItemPrefab, contentParent, false);
            spawnedObjects.Add(obj);

            CreditsItem itemScript = obj.GetComponent<CreditsItem>();
            if (itemScript != null) {
                itemScript.Initialize(item);
            } else {
                Debug.LogWarning("[CreditsUI] Credit Item Prefab missing 'CreditsItem' script!");
            }
        }
    }
}
