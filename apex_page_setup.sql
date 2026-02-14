-- ==============================================================
-- APEX PAGE SETUP - Dynamic Actions & HTML Templates
-- ==============================================================
-- These are the APEX page-level configurations.
-- Follow the DOCX guide for step-by-step setup.
-- ==============================================================


-- ==============================================================
-- PAGE: Student Detail (e.g., Page 3)
-- ==============================================================

-- -------------------------------------------------------
-- DYNAMIC ACTION: "Analyze with Python ML"
-- Trigger: Click on ANALYZE_PERFORMANCE button
-- True Action 1: Execute Server-side Code
-- -------------------------------------------------------

-- PL/SQL Code for the Dynamic Action:
BEGIN
    call_python_analyzer(
        p_student_id   => :P3_STUDENT_ID,
        p_api_base_url => 'https://YOUR-APP-NAME.onrender.com'
    );
END;

-- Items to Submit: P3_STUDENT_ID
-- Items to Return: (none)

-- True Action 2: Refresh Region "Prediction Results"
-- True Action 3: Refresh Region "Charts"
-- True Action 4: Execute JavaScript Code:

-- JavaScript to show success message:
apex.message.showPageSuccess("Python ML analysis complete!");


-- -------------------------------------------------------
-- REGION: Prediction Results (Classic Report)
-- Source SQL:
-- -------------------------------------------------------

SELECT 
    prediction_date AS "Analyzed On",
    predicted_grade AS "Predicted Grade",
    predicted_average AS "Predicted Avg",
    risk_level AS "Risk Level",
    confidence_score AS "Confidence",
    score_trend AS "Score Trend",
    ml_method AS "ML Method",
    recommendation AS "Recommendation"
FROM performance_predictions
WHERE student_id = :P3_STUDENT_ID
ORDER BY prediction_date DESC
FETCH FIRST 5 ROWS ONLY;


-- -------------------------------------------------------
-- REGION: Performance Radar Chart (Static Content / HTML)
-- Source: PL/SQL (Dynamic Content)
-- -------------------------------------------------------

-- PL/SQL Function Body returning CLOB:
DECLARE
    v_chart CLOB;
BEGIN
    SELECT chart_performance INTO v_chart
    FROM performance_predictions
    WHERE student_id = :P3_STUDENT_ID
    AND chart_performance IS NOT NULL
    ORDER BY prediction_date DESC
    FETCH FIRST 1 ROW ONLY;
    
    IF v_chart IS NOT NULL THEN
        RETURN '<div style="text-align:center; background:#1a1a2e; 
                padding:20px; border-radius:12px; margin:10px 0;">
                <h3 style="color:#00d4ff; margin-bottom:15px;">
                    Performance Radar (Python ML)
                </h3>
                <img src="data:image/png;base64,' || v_chart || '" 
                     style="max-width:100%; border-radius:8px;" 
                     alt="Performance Radar Chart"/>
                </div>';
    ELSE
        RETURN '<div style="text-align:center; padding:40px; 
                color:#666; background:#f5f5f5; border-radius:12px;">
                <p>Click <b>Analyze with Python ML</b> to generate charts.</p>
                </div>';
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '<div style="text-align:center; padding:40px; 
                color:#666; background:#f5f5f5; border-radius:12px;">
                <p>Click <b>Analyze with Python ML</b> to generate charts.</p>
                </div>';
END;


-- -------------------------------------------------------
-- REGION: Trend Analysis Chart (Static Content / HTML)  
-- Source: PL/SQL (Dynamic Content)
-- -------------------------------------------------------

-- PL/SQL Function Body returning CLOB:
DECLARE
    v_chart CLOB;
BEGIN
    SELECT chart_trend INTO v_chart
    FROM performance_predictions
    WHERE student_id = :P3_STUDENT_ID
    AND chart_trend IS NOT NULL
    ORDER BY prediction_date DESC
    FETCH FIRST 1 ROW ONLY;
    
    IF v_chart IS NOT NULL THEN
        RETURN '<div style="text-align:center; background:#1a1a2e; 
                padding:20px; border-radius:12px; margin:10px 0;">
                <h3 style="color:#ffd93d; margin-bottom:15px;">
                    Trend Analysis (Python ML)
                </h3>
                <img src="data:image/png;base64,' || v_chart || '" 
                     style="max-width:100%; border-radius:8px;" 
                     alt="Trend Analysis Chart"/>
                </div>';
    ELSE
        RETURN '<div style="text-align:center; padding:40px; 
                color:#666; background:#f5f5f5; border-radius:12px;">
                <p>Trend chart will appear after analysis.</p>
                </div>';
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '<div style="text-align:center; padding:40px; 
                color:#666; background:#f5f5f5; border-radius:12px;">
                <p>Trend chart will appear after analysis.</p>
                </div>';
END;


-- -------------------------------------------------------
-- REGION: Risk Level Card (Static Content / HTML)
-- Source: PL/SQL (Dynamic Content) 
-- -------------------------------------------------------

-- PL/SQL Function Body returning CLOB:
DECLARE
    v_grade     VARCHAR2(2);
    v_risk      VARCHAR2(20);
    v_avg       NUMBER;
    v_trend     NUMBER;
    v_conf      NUMBER;
    v_bg_color  VARCHAR2(20);
    v_risk_color VARCHAR2(20);
BEGIN
    SELECT predicted_grade, risk_level, predicted_average, 
           score_trend, confidence_score
    INTO v_grade, v_risk, v_avg, v_trend, v_conf
    FROM performance_predictions
    WHERE student_id = :P3_STUDENT_ID
    ORDER BY prediction_date DESC
    FETCH FIRST 1 ROW ONLY;
    
    -- Set colors
    CASE v_risk
        WHEN 'Critical' THEN v_risk_color := '#e74c3c';
        WHEN 'High'     THEN v_risk_color := '#e67e22';
        WHEN 'Medium'   THEN v_risk_color := '#f1c40f';
        WHEN 'Low'      THEN v_risk_color := '#2ecc71';
        ELSE v_risk_color := '#95a5a6';
    END CASE;
    
    CASE v_grade
        WHEN 'A' THEN v_bg_color := '#27ae60';
        WHEN 'B' THEN v_bg_color := '#2980b9';
        WHEN 'C' THEN v_bg_color := '#f39c12';
        WHEN 'D' THEN v_bg_color := '#e67e22';
        ELSE v_bg_color := '#e74c3c';
    END CASE;
    
    RETURN '
    <div style="display:flex; gap:15px; flex-wrap:wrap; margin:10px 0;">
        <!-- Grade Card -->
        <div style="flex:1; min-width:150px; background:' || v_bg_color || '; 
             color:white; padding:25px; border-radius:12px; text-align:center;">
            <div style="font-size:48px; font-weight:bold;">' || v_grade || '</div>
            <div style="font-size:14px; opacity:0.9;">Predicted Grade</div>
            <div style="font-size:18px; margin-top:8px;">' || v_avg || '%</div>
        </div>
        <!-- Risk Card -->
        <div style="flex:1; min-width:150px; background:' || v_risk_color || '; 
             color:white; padding:25px; border-radius:12px; text-align:center;">
            <div style="font-size:28px; font-weight:bold;">' || v_risk || '</div>
            <div style="font-size:14px; opacity:0.9;">Risk Level</div>
        </div>
        <!-- Trend Card -->
        <div style="flex:1; min-width:150px; background:#2c3e50; 
             color:white; padding:25px; border-radius:12px; text-align:center;">
            <div style="font-size:28px; font-weight:bold;">' 
                || CASE WHEN v_trend > 0 THEN '+' ELSE '' END 
                || v_trend || '</div>
            <div style="font-size:14px; opacity:0.9;">Score Trend</div>
            <div style="font-size:24px; margin-top:5px;">' 
                || CASE WHEN v_trend > 0 THEN '&#x2191;' ELSE '&#x2193;' END 
                || '</div>
        </div>
        <!-- Confidence Card -->
        <div style="flex:1; min-width:150px; background:#8e44ad; 
             color:white; padding:25px; border-radius:12px; text-align:center;">
            <div style="font-size:28px; font-weight:bold;">' 
                || ROUND(v_conf * 100) || '%</div>
            <div style="font-size:14px; opacity:0.9;">ML Confidence</div>
            <div style="font-size:12px; margin-top:8px; opacity:0.7;">sklearn LinearRegression</div>
        </div>
    </div>';
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '<div style="text-align:center; padding:30px; 
                color:#666; background:#f5f5f5; border-radius:12px;">
                <p style="font-size:16px;">No predictions yet. 
                Click <b>Analyze with Python ML</b> to start.</p>
                </div>';
END;


-- ==============================================================
-- PAGE: Dashboard (e.g., Page 5)
-- ==============================================================

-- -------------------------------------------------------
-- REGION: Student Risk Overview (Cards)
-- -------------------------------------------------------

SELECT 
    student_id,
    student_name,
    predicted_grade,
    risk_level,
    predicted_average,
    current_avg_score,
    current_avg_attendance,
    risk_badge_class,
    grade_badge_class,
    CASE risk_level
        WHEN 'Critical' THEN 1
        WHEN 'High'     THEN 2
        WHEN 'Medium'   THEN 3
        WHEN 'Low'      THEN 4
        ELSE 5
    END AS risk_order
FROM v_student_dashboard
ORDER BY risk_order, student_name;


-- -------------------------------------------------------
-- REGION: Grade Distribution (Chart - Pie)
-- -------------------------------------------------------

SELECT 
    predicted_grade AS label,
    COUNT(*) AS value
FROM v_student_dashboard
WHERE predicted_grade IS NOT NULL
GROUP BY predicted_grade
ORDER BY predicted_grade;


-- -------------------------------------------------------
-- REGION: Risk Distribution (Chart - Donut)
-- -------------------------------------------------------

SELECT 
    risk_level AS label,
    COUNT(*) AS value
FROM v_student_dashboard
WHERE risk_level IS NOT NULL
GROUP BY risk_level
ORDER BY CASE risk_level
    WHEN 'Critical' THEN 1
    WHEN 'High' THEN 2
    WHEN 'Medium' THEN 3
    WHEN 'Low' THEN 4
END;


-- -------------------------------------------------------
-- BUTTON: Analyze All Students
-- Dynamic Action PL/SQL:
-- -------------------------------------------------------

BEGIN
    analyze_all_students(
        p_api_base_url => 'https://YOUR-APP-NAME.onrender.com'
    );
END;


-- ==============================================================
-- PAGE CSS (Add to Page > CSS > Inline)
-- ==============================================================

/*
/* Custom styles for the Student Analyzer */
.t-Cards-item {
    transition: transform 0.2s ease;
}
.t-Cards-item:hover {
    transform: translateY(-2px);
}
.risk-Critical, .risk-High {
    border-left: 4px solid #e74c3c !important;
}
.risk-Medium {
    border-left: 4px solid #f1c40f !important;
}
.risk-Low {
    border-left: 4px solid #2ecc71 !important;
}
*/
