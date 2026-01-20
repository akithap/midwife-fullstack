from sqlalchemy.orm import Session
from datetime import date
from . import models, schemas

# --- Risk Engine ---
# Encapsulates all medical logic for risk assessment and personalized tips.

class RiskEngine:
    
    @staticmethod
    def _create_alert(db: Session, mother_id: int, severity: str, alert_type: str, message: str):
        # Check if identical unresolved alert exists to avoid duplicates
        existing = db.query(models.Alert).filter(
            models.Alert.mother_id == mother_id,
            models.Alert.alert_type == alert_type,
            models.Alert.is_resolved == False
        ).first()
        
        if not existing:
            alert = models.Alert(
                mother_id=mother_id,
                severity=severity,
                alert_type=alert_type,
                message=message
            )
            db.add(alert)
            db.commit()
            
            # If Severity is High, update Mother's global risk status
            if severity == "High":
                mother = db.query(models.Mother).filter(models.Mother.id == mother_id).first()
                if mother:
                    mother.risk_level = "High"
                    db.commit()

    @staticmethod
    def evaluate_static_risks(db: Session, mother: models.Mother, record: models.PregnancyRecord):
        """Evaluates risks appearing in the H512 Registration Form."""
        
        name = mother.full_name.split(" ")[0] # First name for personalization
        
        # 1. Age Risk
        if record.mother_age:
            if record.mother_age < 18:
                msg = f"Hey {name}, being a young mother means you need extra care. Please attend every clinic session and don't hesitate to ask us anything."
                RiskEngine._create_alert(db, mother.id, "High", "Teenage Pregnancy", msg)
            elif record.mother_age > 35:
                msg = f"Hey {name}, at your age, we need to be careful about blood pressure and sugar. Please rest well and monitor your health."
                RiskEngine._create_alert(db, mother.id, "Medium", "Maternal Age", msg)

        # 2. BMI Risk
        if record.bmi:
            if record.bmi < 18.5:
                msg = f"Hey {name}, your BMI is low. Good nutrition is vital for the baby. Try to eat frequent, protein-rich meals."
                RiskEngine._create_alert(db, mother.id, "Medium", "Low BMI", msg)
            elif record.bmi > 30:
                msg = f"Hey {name}, let's keep an eye on your weight. Gentle walking and a balanced diet will help you and the baby stay healthy."
                RiskEngine._create_alert(db, mother.id, "High", "High BMI", msg)
                
        # 3. Parity (Grand Multipara)
        if record.gravidity and record.gravidity >= 5:
             msg = f"Hey {name}, having many pregnancies can weaken the uterus. We strongly recommend a hospital delivery for safety."
             RiskEngine._create_alert(db, mother.id, "High", "Grand Multipara", msg)
             
        # 4. Medical History
        if record.risk_diabetes or record.family_diabetes:
             msg = f"Hey {name}, due to diabetes risk, please avoid sugary sweets and focus on whole grains like brown rice."
             RiskEngine._create_alert(db, mother.id, "High", "Diabetes Risk", msg)
             
        if record.risk_cardiac:
             msg = f"Hey {name}, your heart condition requires special care. Please limit physical exertion and keep your specialist appointments."
             RiskEngine._create_alert(db, mother.id, "High", "Cardiac Condition", msg)

    @staticmethod
    def evaluate_dynamic_risks(db: Session, mother: models.Mother, visit: models.ANCVisit):
        """Evaluates risks from an ongoing ANC Clinic Visit."""
        
        name = mother.full_name.split(" ")[0]
        
        # 1. Hypertension (Preeclampsia)
        if (visit.bp_systolic and visit.bp_systolic >= 140) or (visit.bp_diastolic and visit.bp_diastolic >= 90):
             msg = "High Blood Pressure detected." # Static internal message
             RiskEngine._create_alert(db, mother.id, "High", "Hypertension", msg)
             
        # 2. Gestational Diabetes (Urine Sugar)
        if visit.urine_sugar in ["+", "++", "+++"]:
             msg = "Sugar detected in urine."
             RiskEngine._create_alert(db, mother.id, "Medium", "Diabetes", msg)
             
        # 3. Proteinuria (Pre-eclampsia sign)
        if visit.urine_albumin in ["+", "++", "+++"]:
             msg = "Protein detected in urine."
             RiskEngine._create_alert(db, mother.id, "High", "Proteinuria", msg)
             
        # 4. Fetal Issues
        if visit.fetal_heart_sound == "-" or visit.fetal_movement == "-":
             msg = "Reduced fetal activity reported."
             RiskEngine._create_alert(db, mother.id, "High", "Fetal Activity", msg)

    # --- SMART TIP ROTATOR ---
    
    TIP_LIBRARY = {
        "Hypertension": [
            "Rest on your left side for at least 30 minutes twice a day to improve blood flow to the baby.",
            "Avoid adding extra salt to your rice and curries. Natural flavors are best for you right now.",
            "If you get a severe headache or blurred vision, don't wait—go to the hospital immediately.",
            "Stress raises blood pressure. Take 10 minutes today to sit quietly and breathe deeply.",
            "Make sure you take your prescribed pressure medications exactly as the doctor ordered.",
            "Swelling in your legs? Keep your feet elevated on a pillow when resting.",
            "Avoid fried snacks (short eats) and salty packets. Fresh fruit is a safer choice.",
            "Drink plenty of water. Staying hydrated helps manage your blood pressure.",
            "If you feel dizzy or see 'stars', sit down immediately and call for help.",
            "Regular clinic visits are crucial. Never miss a BP check appointment."
        ],
        "Diabetes": [
            "Cut down on sugary tea and biscuits. Try a cup of plain tea with a piece of fruit instead.",
            "Brown rice or Red rice releases sugar slowly. It's better than White rice for you.",
            "Eat small meals often rather than three heavy plates of rice.",
            "Vegetables like Bitter Gourd (Karawila) and Okra are great for controlling sugar.",
            "A 15-minute gentle walk after meals helps lower your blood sugar naturally.",
            "Avoid sugary drinks like soda or cordial. Water or Thambili (King Coconut) is best.",
            "Watch out for hidden sugars in processed foods and jams.",
            "If you feel shaky or sweating (low sugar), eat a toffee immediately and tell your midwife.",
            "Fiber-rich foods like lentils (dhal) and chickpeas help keep sugar steady.",
            "Excessive weight gain can worsen diabetes. Stick to the diet plan given by the clinic."
        ],
        "Proteinuria": [
            "Protein in urine can be a sign of kidney strain. Drink at least 3 liters of water daily.",
            "Watch for sudden swelling in your face or hands. It’s a warning sign.",
            "This condition needs close monitoring. Please count your baby's kicks carefully every day.",
            "Rest is your best medicine right now. Avoid heavy household work.",
            "A high-protein diet (eggs, fish, soy) can help replace what is lost, but ask your doctor first.",
            "If your urine looks frothy or dark, report it to the midwife immediately.",
            "Severe stomach pain (upper belly) is a danger sign. Go to the hospital if it happens.",
            "Measure your blood pressure daily if you have a home monitor.",
            "Left-side sleeping helps your kidneys filter waste better.",
            "Make sure to attend every urine test appointment without fail."
        ],
        "Teenage Pregnancy": [
            "Your body is still growing too. You need extra calcium (milk, sprats) for both you and the baby.",
            "Don't be afraid to ask questions. We are here to help you become a great mom.",
            " attending 'Antenatal Classes' helps you prepare for labor. Bring your partner or mom along!",
            "Avoid heavy lifting. Your bones are still developing strength.",
            "Emotional support is important. Talk to your PHM if you feel overwhelmed or sad.",
            "Make sure to take your Folic Acid and Iron tablets every single day.",
            "Eat plenty of greens and fruits to keep your skin and baby healthy.",
            "Education is important. You can continue your studies while being a great mom.",
            "Learn about breastfeeding early. It’s the best gift for your baby.",
            "Ensure you have a support person ready for when labor starts."
        ],
        "Maternal Age": [
            "At your age, rest is essential. Don't overexert yourself with heavy chores.",
            "We check your sugar and pressure more often just to be safe. It's standard procedure.",
            "Genetic screening/scans are recommended to ensure the baby is developing perfectly.",
            "Keep active with gentle yoga or walking, but listen to your body.",
            "Leg cramps? Calcium and Magnesium rich foods like leafy greens can help.",
            "Preparedness reduces stress. Pack your hospital bag a few weeks early.",
            "Stay hydrated to prevent urinary infections, which are more common.",
            "Join a support group. Experienced moms have a lot of wisdom to share.",
            "Watch your weight gain. Harder to lose it later, but necessary for baby now.",
            "High blood pressure is a common risk. Regular checks are your best prevention."
        ],
        "Low BMI": [
            "You need to gain weight for the baby. Add an extra snack between every meal.",
            "Add a spoonful of coconut oil or butter to your rice for healthy extra calories.",
            "Eat nutrient-dense foods: Avocados, Nuts, Eggs, and Full-cream milk.",
            "Don't skip meals. The baby needs a steady supply of nutrients.",
            "If you feel nauseous, try dry crackers before getting out of bed.",
            "Bananas are great energy boosters. Have two a day.",
            "Protein builds the baby. Try to eat Fish, Chicken, or Soya every day.",
            "Drink calorie-rich fluids like fresh fruit smoothies or milkshakes.",
            "Rest after meals to help your body absorb the nutrients.",
            "Take your vitamins! They cover any gaps in your diet."
        ],
        "High BMI": [
            "Focus on quality, not quantity. Nutrient-rich foods over calorie-heavy ones.",
            "Swap fried snacks for fresh fruit or boiled gram (chickpeas).",
            "Walking 30 mins a day is safe and keeps your weight in check.",
            "Drink a glass of water before meals to avoid overeating.",
            "White bread and buns spike your sugar. Choose wholemeal bread or kurakkan.",
            "Monitor your blood pressure regularly as weight adds strain.",
            "Avoid late-night heavy dinners. Eat light at night.",
            "Sugar-sweetened beverages are the main enemy. Switch to water.",
            "Breastfeeding helps you lose weight after birth! Prepare for it now.",
            "Slow weight gain is okay. You don't need to 'eat for two' literally."
        ],
        "Grand Multipara": [
            "Your uterus has worked hard before. Hospital delivery is safer than a home birth.",
            "Post-delivery bleeding is a risk. Have a helper ready for the first week at home.",
            "Rest is crucial. Let older children help with small household tasks.",
            "Pelvic floor exercises (Kegels) are vital to prevent weakness later.",
            "Nutrition is key. Replenish your iron stores with green leaves and meats.",
            "Watch for early labor signs. It might happen faster than your previous births.",
            "Discuss family planning now. Knowing your future plan helps current peace of mind.",
            "Back pain is common. Watch your posture when lifting existing children.",
            "Varicose veins (leg veins) might flare up. Keep legs elevated when sitting.",
            "You are an expert mom, but every pregnancy is different. Listen to this one."
        ],
        "Fetal Activity": [
            "Count your baby's kicks: 10 kicks within 12 hours is a good sign.",
            "If the baby is quiet, drink a cold sweet drink and lie on your left side to wake them.",
            "Talk to your baby! They can hear you and often respond with movement.",
            "Active mostly at night? That's normal. Babies sleep when you walk.",
            "Any sudden decrease in movement is a reason to come to the hospital. Don't wait.",
            "Hiccups feel like rhythmic little jumps. It's normal and healthy.",
            "Track the movements at the same time every day for consistency.",
            "Feeling the baby move is the best reassurance. Enjoy those moments.",
            "If you are unsure, come to the clinic. We are happy to check the heartbeat.",
            "A kick chart is a handy tool. Mark the movements daily."
        ]
    }

    @staticmethod
    def get_daily_tip(alert_type: str, mother_name: str, day_of_year: int):
        """Selects a tip based on the day to ensure rotation."""
        tips = RiskEngine.TIP_LIBRARY.get(alert_type, ["Stay hydrated and attend your clinics."])
        
        # Rotation Logic: (DayOfYear) % count
        # This ensures everyone gets the same sequence but it changes daily.
        # To personalize per user (so all HTN moms don't get same tip same day), add ID if passed.
        # For now, simplistic daily rotation is fine.
        idx = day_of_year % len(tips)
        raw_tip = tips[idx]
        
        return f"Hey {mother_name}, {raw_tip}"
             
