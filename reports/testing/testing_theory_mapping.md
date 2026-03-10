# Testing Concepts Map: Theory to Project

This document maps the testing theories you've learned to the specific implementation in your Password Manager project.

## 1. Integration & Architecture
| Theory Concept | Project Implementation |
| :--- | :--- |
| **Systematic Technique** | We use the `integration_test` package to build tests that exercise the UI and Services together. |
| **Program Structure via Design** | Your app follows a clear separation (UI in `lib/pages`, Services in `lib/services`). Integration tests ensure these layers connect correctly. |
| **Top-Down / Bottom-Up** | We are currently using a **Bottom-Up** approach: Unit tests (`test/`) verify logic first, followed by Integration tests (`integration_test/`) that verify the assembled pages. |

## 2. Regression & Smoke Testing
| Theory Concept | Project Implementation |
| :--- | :--- |
| **Regression Testing** | The CI/CD teammate added a GitHub Action. This automatically re-runs your unit and widget tests on every `git push` to catch side effects. |
| **Regression Test Suite** | 1. **Representative Sample:** `widget_test.dart` and `vault_page_test.dart`. <br> 2. **Affected Functions:** Focus on `auth_service.dart` during login changes. <br> 3. **Changed Components:** Testing specific UI widgets like `backup_dialog.dart`. |
| **Smoke Testing** | The [app_test.dart](file:///m:/password_manager_app/password_manager_app/integration_test/app_test.dart) I created is your first **Smoke Test**. It does a daily check: "Does the app even open to the login screen?" |

## 3. Mobile Specific Strategies
| Theory Concept | Project Implementation |
| :--- | :--- |
| **UI & Navigation** | Covered by `integration_test`. We verify that clicking "Settings" actually navigates to `SettingsPage`. |
| **Performance Testing** | **Planned:** We need to measure how long it takes to encrypt/decrypt a large vault of 100+ passwords. |
| **Connectivity Testing** | **To-Do:** Testing how the app behaves when the user loses Wi-Fi during a sync operation. |
| **Testing-in-the-wild** | This involves you installing the built `.apk` or `.ipa` on your own phone and using it throughout your day. |

## 4. Validation Testing
| Theory Concept | Project Implementation |
| :--- | :--- |
| **User Stories** | We validate against your specific user stories (e.g., US 5.12 for Log Encryption). |
| **Alpha/Beta Testing** | This will happen when you distribute the app to your teammates or family members via **TestFlight** or **Google Play Internal Testing**. |

---

## When to use Device vs. Emulator?

| Feature | Choose Emulator/Simulator | Choose Real Device |
| :--- | :---: | :---: |
| **Basic UI Layout / Logic** | ✅ (Fastest) | ❌ (Slower to deploy) |
| **Keyboard Interaction** | ✅ | ❌ (Desktop keyboard differs) |
| **Performance / Smoothness** | ❌ (Host PC is too fast) | ✅ (Realistic CPU/RAM) |
| **Battery / Heat Testing** | ❌ | ✅ |
| **Network (3G/4G/Offline)** | ❌ (Spoofing is unreliable) | ✅ (Real network behavior) |
| **Biometrics (Fingerprint/FaceID)**| ❌ (Hard to simulate) | ✅ (Essential for security) |

**Rule of Thumb:** Use an **Emulator** for 90% of your daily development (coding and debugging). Use a **Real Device** for the final 10% of testing before you ship a new version or when debugging hardware-specific issues.
