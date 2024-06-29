CREATE TABLE Students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(100) NOT NULL,
    gpa DECIMAL(3, 2) NOT NULL
    -- Add other relevant student details as needed
);
CREATE TABLE Subjects (
    subject_id INT PRIMARY KEY,
    subject_name VARCHAR(100) NOT NULL,
    total_seats INT NOT NULL,
    available_seats INT NOT NULL
    -- Add other relevant subject details as needed
);
CREATE TABLE StudentPreferences (
    student_id INT,
    preference_order INT,
    subject_id INT,
    PRIMARY KEY (student_id, preference_order),
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (subject_id) REFERENCES Subjects(subject_id)
);
-- Select students and their preferred subjects based on GPA and available seats
WITH RankedStudents AS (
    SELECT 
        s.student_id,
        s.gpa,
        sp.preference_order,
        sp.subject_id,
        ROW_NUMBER() OVER (PARTITION BY s.student_id ORDER BY s.gpa DESC) AS rank
    FROM Students s
    JOIN StudentPreferences sp ON s.student_id = sp.student_id
    JOIN Subjects subj ON sp.subject_id = subj.subject_id
    WHERE subj.available_seats > 0  -- Only consider subjects with available seats
)
UPDATE Subjects subj
SET available_seats = available_seats - 1
WHERE subject_id IN (
    SELECT subject_id
    FROM RankedStudents
    WHERE rank = 1  -- Allocate to students with highest GPA first
);

-- Mark students as unallocated if all preferences are full
UPDATE Students
SET allocated = CASE 
    WHEN EXISTS (
        SELECT 1
        FROM StudentPreferences sp
        LEFT JOIN Subjects subj ON sp.subject_id = subj.subject_id AND subj.available_seats > 0
        WHERE Students.student_id = sp.student_id AND subj.subject_id IS NULL
    ) THEN 'No'
    ELSE 'Yes'
END;
-- Retrieve allocated subjects for each student
SELECT 
    s.student_id,
    s.student_name,
    subj.subject_id,
    subj.subject_name,
    sp.preference_order
FROM Students s
JOIN StudentPreferences sp ON s.student_id = sp.student_id
JOIN Subjects subj ON sp.subject_id = subj.subject_id
WHERE subj.available_seats = 0;  -- Retrieve only allocated subjects
