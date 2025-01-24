% Diagnostic Rules for Nervous System Disorders

:- consult('disease_facts.pl').
:- consult('symptoms_facts.pl').

/* diagnose/3: Diagnoses a disease based on symptoms */
diagnose(Disease, Symptoms, Severity) :-
    disease_symptoms(Disease, DiseaseSymptoms),
    match_symptoms(Symptoms, DiseaseSymptoms, MatchPercentage),
    evaluate_severity(MatchPercentage, Severity),
    (MatchPercentage >= 30).

/* match_symptoms/3: Calculates the percentage of matching symptoms */
match_symptoms(PatientSymptoms, DiseaseSymptoms, MatchPercentage) :-
    intersection(PatientSymptoms, DiseaseSymptoms, MatchingSymptoms),
    length(MatchingSymptoms, MatchCount),
    length(DiseaseSymptoms, TotalSymptoms),
    MatchPercentage is (MatchCount / TotalSymptoms) * 100.

/* evaluate_severity/2: Determines the severity level based on match percentage */
evaluate_severity(MatchPercentage, Severity) :-
    ( MatchPercentage >= 70 -> Severity = severe;
      MatchPercentage >= 50 -> Severity = moderate;
      MatchPercentage > 30 -> Severity = mild;
      Severity = none ).

/* display_disease_information/1: Displays disease details for debugging */
display_disease_information(DiseaseID) :-
    (   disease(DiseaseID, DiseaseName),
        summary(DiseaseID, Summary),
        link(DiseaseID, Link)
    ->  format('Disease: ~w~nSummary: ~w~nLink: ~w~n', [DiseaseName, Summary, Link])
    ;   format('No detailed information found for DiseaseID: ~w~n', [DiseaseID])
    ).
