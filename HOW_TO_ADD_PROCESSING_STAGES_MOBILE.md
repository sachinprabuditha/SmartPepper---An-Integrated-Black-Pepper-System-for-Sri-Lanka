# 🏭 How to Add Processing Stages in Mobile App

## ✨ New Feature Added!

You can now add all processing stages directly from the mobile app as a farmer!

---

## 📱 Where to Find It

1. **Open your lot** in the mobile app
2. Go to **Lot Details** screen
3. Scroll down to the **"Certifications & Compliance"** card
4. You'll see **3 buttons**:
   - 📜 **Add Certificate** - Add certifications
   - ✅ **Check Compliance** - Run compliance checks
   - 🏭 **Add Processing Stage** - ⭐ NEW! Add processing stages

---

## 🎯 How to Add Processing Stages

### Step 1: Click "Add Processing Stage" Button

### Step 2: Select Stage Type

Choose from 5 stage types:

- 🌾 **Harvest** - Initial pepper harvesting from farm
- 🌡️ **Drying** - Drying process to reduce moisture
- 📊 **Grading** - Quality grading and sorting
- 📦 **Packaging** - Packing for storage or export
- 🏪 **Storage** - Storage in controlled conditions

### Step 3: Fill Common Fields

- **Stage Name**: Auto-filled based on type (e.g., "Harvest Process")
- **Location**: Where this stage happened (e.g., "Matara Pepper Estate")
- **Operator Name**: Who performed this stage (e.g., "Farm Worker Team")
- **Stage Date**: When this happened (defaults to today)
- **Notes**: Optional additional information

### Step 4: Fill Stage-Specific Metrics

#### 🌾 For Harvest Stage:

- **Yield (kg)**: Total harvest weight (e.g., 52)
- **Quality Score**: 0-100 (e.g., 95)
- **Harvest Method**: Manual or Mechanical

#### 🌡️ For Drying Stage:

- **Moisture Content (%)**: ⚠️ Must be ≤12.5% for EU export! (e.g., 11.8)
- **Temperature (°C)**: Drying temperature (e.g., 28)
- **Duration (hours)**: How long dried (e.g., 72)

#### 📊 For Grading Stage:

- **Quality Grade**: AAA, AA, A, B, or C
- **Color**: Black, White, or Green
- **Uniformity (%)**: Consistency percentage (e.g., 95)

#### 📦 For Packaging Stage:

- **Package Material**: Choose from:
  - Food grade plastic ✅
  - HDPE ✅
  - PP ✅
  - PET ✅
  - Glass ✅
  - Jute with liner ✅
- **Pack Size**: e.g., 500g, 1kg
- **Number of Packs**: Total units (e.g., 100)

#### 🏪 For Storage Stage:

- **Storage Type**: e.g., Cold Storage, Warehouse
- **Storage Temperature (°C)**: e.g., 20
- **Humidity (%)**: e.g., 60

### Step 5: Click "Add Processing Stage"

The stage will be added to your lot's traceability chain!

---

## ✅ Complete Traceability Chain

To pass **EU Compliance**, you need all 4 stages:

1. 🌾 **Harvest** → 2. 🌡️ **Drying** → 3. 📊 **Grading** → 4. 📦 **Packaging**

### Example: Adding All 4 Stages

#### Stage 1: Harvest

- Type: **Harvest**
- Name: **Pepper Harvesting**
- Location: **Matara Pepper Estate**
- Operator: **Farm Worker Team**
- Date: (Select harvest date)
- Yield: **52 kg**
- Quality Score: **95**
- Harvest Method: **Manual**
- Notes: **Harvested at optimal maturity**

#### Stage 2: Drying

- Type: **Drying**
- Name: **Drying Process**
- Location: **Matara Processing Facility**
- Operator: **Processing Team A**
- Date: (Day after harvest)
- Moisture: **11.8%** ⚠️ Must be ≤12.5%
- Temperature: **28°C**
- Duration: **72 hours**
- Notes: **Dried to EU export standards**

#### Stage 3: Grading

- Type: **Grading**
- Name: **Grading Process**
- Location: **Matara Quality Control**
- Operator: **QC Inspector**
- Date: (Day after drying)
- Grade: **A**
- Color: **Black**
- Uniformity: **95%**
- Notes: **Graded per international standards**

#### Stage 4: Packaging

- Type: **Packaging**
- Name: **Packaging Process**
- Location: **Matara Packaging Unit**
- Operator: **Packaging Team B**
- Date: (Day after grading)
- Material: **Food_grade_plastic**
- Pack Size: **500g**
- Pack Count: **100 units**
- Notes: **EU-approved materials**

---

## 🎯 Tips for EU Compliance

### Critical Requirements:

1. **Moisture Content** (Drying stage):

   - ✅ Must be **≤12.5%** for EU
   - ⚠️ The form will warn you if higher

2. **Package Material** (Packaging stage):

   - ✅ Must be **food-grade**
   - Choose: Food_grade_plastic, HDPE, PP, PET, Glass, or Jute_with_liner

3. **Complete Chain**:

   - ✅ Must have: Harvest → Drying → Grading → Packaging
   - Missing stages = Failed "Full Traceability Chain" check

4. **Quality Grade** (Grading stage):
   - ✅ EU accepts: A, AA, or AAA
   - ⚠️ B and C grades don't meet EU standards

---

## 📊 After Adding All Stages

1. Go back to **Lot Details**
2. Click **"Check Compliance"**
3. Select **"EU"** market
4. All checks should pass! ✅

### Expected Result:

```
✓ EU Organic Certification Required
✓ Fumigation Certificate Required
✓ EU Quality Standards
✓ Pesticide Residue Limits
✓ Moisture Content Standard (11.8% ≤ 12.5%)
✓ Food Grade Packaging Required
✓ Full Traceability Chain (Harvest → Drying → Grading → Packaging)
```

**Status: PASSED** 🎉

---

## 🔄 View Your Processing Stages

After adding stages:

1. Go to **"Blockchain Traceability"** tab
2. Click **"Processing"** tab
3. See all your processing stages with timeline

---

## 🚨 Common Issues

### Issue 1: "Missing required fields"

**Solution**: Make sure you filled:

- Stage Type ✓
- Stage Name ✓
- Location ✓
- Operator Name ✓
- All stage-specific metrics ✓

### Issue 2: "Compliance check fails for moisture"

**Solution**:

- Moisture must be ≤12.5%
- Edit drying stage to lower moisture content

### Issue 3: "Full Traceability Chain fails"

**Solution**:

- Make sure you added all 4 stages:
  - Harvest ✓
  - Drying ✓
  - Grading ✓
  - Packaging ✓

### Issue 4: "Package material not accepted"

**Solution**:

- Use food-grade materials:
  - Food_grade_plastic ✅
  - HDPE, PP, PET, Glass ✅
  - NOT regular plastic ❌

---

## 💡 Best Practices

1. **Add stages in order**: Harvest → Drying → Grading → Packaging
2. **Use correct dates**: Set dates chronologically (harvest first, packaging last)
3. **Record accurate metrics**: Especially moisture content and quality grade
4. **Add detailed notes**: Helps with audits and transparency
5. **Use food-grade materials**: For packaging stage

---

## 🎊 Success!

Once you add all 4 processing stages with correct metrics:

- ✅ Complete traceability chain established
- ✅ EU compliance requirements met
- ✅ Lot ready for international export
- ✅ Blockchain traceability fully operational

**Your SmartPepper lot is now certified for EU export!** 🌍🚢

---

## 📱 Summary

**Where**: Lot Details → "Certifications & Compliance" card → "Add Processing Stage" button

**What**: 5 stage types (Harvest, Drying, Grading, Packaging, Storage)

**Why**: Complete traceability chain required for EU compliance

**How**: Fill form → Add stage-specific metrics → Submit

**Result**: Full traceability + Pass all compliance checks! 🎉
