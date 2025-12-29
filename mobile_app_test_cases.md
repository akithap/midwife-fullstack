# Mobile Application Test Cases
Midwife Management System

## Table of Contents
1. [Authentication Module](#1-authentication-module)
2. [Midwife Dashboard & Navigation](#2-midwife-dashboard--navigation)
3. [Mother Registration & Management](#3-mother-registration--management)
4. [Pregnancy Registration (H 512 Form)](#4-pregnancy-registration-h-512-form)
5. [Appointment Management](#5-appointment-management)
6. [Mother Portal](#6-mother-portal)
7. [Risk Management](#7-risk-management)

---

## 1. Authentication Module

| TCP ID | Test Case Description | Pre-Conditions | Test Steps | Expected Result | Priority | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-AUTH-01** | Midwife Login - Successful | App is open on Login Screen. | 1. Enter valid Midwife username.<br>2. Enter valid password.<br>3. Tap "Login". | Redirected to Midwife Dashboard. | High | **Pass** |
| **TC-AUTH-02** | Midwife Login - Invalid Credentials | App is open. | 1. Enter invalid username or password.<br>2. Tap "Login". | Show error SnackBar: "Login Failed". Stay on login screen. | High | **Pass** |
| **TC-AUTH-03** | Midwife Login - Empty Fields | App is open. | 1. Leave Username or Password empty.<br>2. Tap "Login". | Validation check fails (if implemented) or API call returns "Login Failed". | Medium | **Pass** |
| **TC-AUTH-04** | Mother Login - Successful | App is open on Mother Login. | 1. Enter valid NIC.<br>2. Enter valid password.<br>3. Tap "Login". | Redirected to Mother Home Screen. | High | **Pass** |
| **TC-AUTH-05** | Mother Login - Invalid | App is open on Mother Login. | 1. Enter invalid NIC/Password.<br>2. Tap "Login". | Show error message. | High | **Pass** |
| **TC-AUTH-06** | Logout | User is logged in. | 1. Tap Profile/Avatar icon.<br>2. Select "Logout". | Session cleared. Redirected to Welcome/Login Screen. | Medium | **Pass** |
| **TC-AUTH-07** | Change Password | User is logged in. | 1. Navigate to Change Password Screen.<br>2. Enter Old Password.<br>3. Enter New Password & Confirm.<br>4. Submit. | Success message displayed. New password works on next login. | Medium | **Pass** |

## 2. Midwife Dashboard & Navigation

| TCP ID | Test Case Description | Pre-Conditions | Test Steps | Expected Result | Priority | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-DASH-01** | Load Dashboard Stats | Midwife Logged in. | 1. Open Dashboard.<br>2. Wait for API response. | "Assigned Mothers" and "Today's Visits" counts are displayed correctly (non-zero if data exists). | High | **Pass** |
| **TC-DASH-02** | View Notifications | Midwife Logged in. | 1. Tap Notification Bell icon. | Modal/Sheet opens showing list of notifications (e.g., Pending appointments). | Low | **Pass** |
| **TC-DASH-03** | Pull to Refresh | Dashboard loaded. | 1. Pull down on the dashboard screen. | Loading indicator spins. Stats are re-fetched from API. | Medium | **Pass** |
| **TC-DASH-04** | Navigation - Quick Actions | Dashboard loaded. | 1. Tap "My Mothers". | Navigate to Mother List Screen. | High | **Pass** |
| **TC-DASH-05** | Navigation - Daily Visits | Dashboard loaded. | 1. Tap "Daily Visits". | Navigate to Appointment Screen. | High | **Pass** |

## 3. Mother Registration & Management

| TCP ID | Test Case Description | Pre-Conditions | Test Steps | Expected Result | Priority | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-MOTH-01** | View Mother List | Midwife Logged in. | 1. Navigate to "My Mothers". | List of registered mothers is displayed with Names and NICs. | High | **Pass** |
| **TC-MOTH-02** | Search Mother | Mother List displayed. | 1. Enter text in search bar (e.g., "Kamala"). | List filters to show mothers matching the name/NIC. | Medium | **Pass** |
| **TC-MOTH-03** | Register New Mother (Admin Info) | Register Screen Open. | 1. Enter Name, NIC, Address, Phone.<br>2. Submit. | New Mother created. Success message displayed. | High | **Pass** |
| **TC-MOTH-04** | Form Validation - Required Fields | Register Screen Open. | 1. Leave "Name" or "NIC" empty.<br>2. Try to Submit. | Form shows "Required" errors. API call is not made. | High | **Pass** |

## 4. Pregnancy Registration (H 512 Form)

| TCP ID | Test Case Description | Pre-Conditions | Test Steps | Expected Result | Priority | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-PREG-01** | Stepper Navigation | Edit/New H512 Form Open. | 1. Fill Step 1 (Admin).<br>2. Tap "Continue". | App proceeds to Step 2 (Personal Info). | High | **Pass** |
| **TC-PREG-02** | BMI Calculation | Step 3 (Vitals) Open. | 1. Enter Height (160 cm).<br>2. Enter Weight (60 kg). | Read-only BMI field updates automatically (approx 23.4). | Medium | **Pass** |
| **TC-PREG-03** | Add Past Pregnancy (Dynamic List) | Step 4 (History) Open. | 1. Tap "Add" icon.<br>2. Fill Outcome, Delivery Mode in dialog.<br>3. Tap "Add". | New entry appears in the list on the main screen. | High | **Pass** |
| **TC-PREG-04** | Auto-Detect Risk - Age | Form Open. | 1. Enter Mother Age = 18.<br>2. Proceed to Risk Step. | "Age < 20 or > 35" risk checkbox is automatically checked. | High | **Pass** |
| **TC-PREG-05** | Auto-Detect Risk - Gravidity| Form Open. | 1. Enter Gravidity = 5.<br>2. Proceed to Risk Step. | "5th Pregnancy or more" risk checkbox is automatically checked. | High | **Pass** |
| **TC-PREG-06** | Submit Form (Risk Calculation) | All steps completed. | 1. Any Risk checkbox is TRUE.<br>2. Tap "Submit". | Form sends `risk_level: "High"` to backend. Success SnackBar shown. | High | **Pass** |
| **TC-PREG-07** | Submit Form (Low Risk) | All steps completed. | 1. All Risk checkboxes FALSE.<br>2. Tap "Submit". | Form sends `risk_level: "Low"` to backend. Success SnackBar shown. | High | **Pass** |

## 5. Appointment Management

| TCP ID | Test Case Description | Pre-Conditions | Test Steps | Expected Result | Priority | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-APPT-01** | Create Appointment | Appointment Form Open. | 1. Select Mother, Date, Time.<br>2. Submit. | Appointment created. Appears in Daily Visits if date is Today. | High | **Pass** |
| **TC-APPT-02** | View Daily Visits | Dashboard. | 1. Navigate to "Daily Visits". | List shows only appointments scheduled for `DateTime.now()`. | High | **Pass** |
| **TC-APPT-03** | Mark Completed | Daily Visits Screen. | 1. Find a "Scheduled" appointment.<br>2. Tap "Mark as Completed". | Status updates to "Completed". UI turns Green/Gray. Button is disabled. | High | **Pass** |
| **TC-APPT-04** | Call Mother | Daily Visits Screen. | 1. Tap Phone Number on card. | System phone dialer opens with the number pre-filled. | Low | **Pass** |
| **TC-APPT-05** | Empty State | No appts for today. | 1. Navigate to "Daily Visits". | "No visits scheduled for today" placeholder is shown. | Low | **Pass** |

## 6. Mother Portal

| TCP ID | Test Case Description | Pre-Conditions | Test Steps | Expected Result | Priority | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-MP-01** | Dashboard Ticket | Mother has pending appt. | 1. Login as Mother. | "Upcoming Appointment" ticket shows correct date/time of next visit. | High | **Pass** |
| **TC-MP-02** | View Health File | Dashboard. | 1. Tap "My Health File". | Shows Loading spinner, then displays Mother Profile and History data. | High | **Pass** |
| **TC-MP-03** | Upcoming Meetings List | Dashboard. | 1. Tap "Upcoming Meetings". | List of all future appointments is shown. sorted by date. | Medium | **Pass** |

## 7. Risk Management

| TCP ID | Test Case Description | Pre-Conditions | Test Steps | Expected Result | Priority | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-RISK-01** | View Risk Stats | Midwife Dashboard. | 1. Tap "Risk Mgmt". | Pie charts or count cards load showing stats (e.g., "5 High Risk Mothers"). | Medium | **Pass** |
| **TC-RISK-02** | Filter by Risk | Risk Mgmt Screen. | 1. Tap "Diabetes" Category. | Screen navigates to a list showing only mothers with Diabetes risk. | High | **Pass** |
