:- module(app, [start_server/0]).

:- use_module(library(http/http_server)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_parameters)).

:- discontiguous disease/2.
:- discontiguous link/2.
:- discontiguous summary/2.

:- consult(diagnostic_rules).
:- consult(symptoms_facts).

% HTTP handler for root page
:- http_handler(root(.), index_handler, []).

% HTTP handler for diagnosis
:- http_handler(root(diagnose), diagnose_handler, [method(post)]).

% Start the server
start_server :- 
    http_server([port(8080)]).

% Index page handler
index_handler(_Request) :-
    findall(Symptom, (disease_symptoms(_, Symptoms), member(Symptom, Symptoms)), AllSymptoms),
    sort(AllSymptoms, UniqueSymptoms),
    reply_html_page(
        [title('Diagnostic Expert System for Nervous System Disorders')],
        [ \style_css,
          div([class='main-container'],
              [ div([class='logo-container'],
                    [img([src='https://static.vecteezy.com/ti/vecteur-libre/p2/2859253-lowpoly-moderne-cerveau-neurone-avec-lumiere-vectoriel.jpg', alt='Diagnostic Expert System Logo', class='logo'])]),
                h1([class='header-title'], 'Diagnostic Expert System for Nervous System Disorders'),
                p([class='description'], 'This system helps in diagnosing various disorders related to the nervous system by analyzing the symptoms provided.'),
                div([class='image-container'],
                    [img([src='https://images.pexels.com/photos/24346263/pexels-photo-24346263/free-photo-of-homme-etre-assis-technologie-fauteuil.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2', alt='Technologie et Diagnostic', class='image1'])]),
                div([class='image-container'],
                    [img([src='https://images.pexels.com/photos/4226219/pexels-photo-4226219.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2', alt='Santé et Technologie', class='image2'])]),
                div([class='form-container'],
                    form([action='/diagnose', method='post'], [
                        h3([class='form-title'], 'Select your symptoms:'),
                        div([class='checkbox-container'], \checkbox_list(UniqueSymptoms)),
                        input([type=submit, value='Diagnose', class='submit-button'])
                    ]))
              ])
        ]).

style_css -->
    html(style(['
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: "Poppins", sans-serif; background: linear-gradient(120deg, #f6f9fc, #e9eff5); color: #333; min-height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: flex-start; }
        .main-container { display: flex; flex-direction: column; align-items: center; padding: 30px; width: 100%; max-width: 1200px; margin-top: 20px; box-shadow: 0 8px 15px rgba(0, 0, 0, 0.1); border-radius: 10px; background-color: #ffffff; }
        .header-title { font-size: 2.5rem; font-weight: 700; color: #2E3B4E; text-align: center; margin-bottom: 20px; text-transform: uppercase; letter-spacing: 1.5px; }
        .description { font-size: 1.2rem; color: #666; text-align: center; margin-bottom: 30px; max-width: 800px; }
        .logo-container { text-align: center; margin-bottom: 20px; }
        .logo { width: 120px; height: auto; }
        .image-container { text-align: center; margin-bottom: 20px; }
        .image1, .image2 { width: 100%; max-width: 600px; border-radius: 15px; box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1); transition: transform 0.3s ease-in-out; }
        .image1:hover, .image2:hover { transform: scale(1.05); }
        .form-container { background-color: #f9f9f9; border-radius: 8px; padding: 30px; max-width: 800px; width: 100%; box-shadow: 0 8px 20px rgba(0, 0, 0, 0.1); }
        .form-title { font-size: 1.5rem; color: #2E3B4E; margin-bottom: 20px; text-align: center; }
        .checkbox-container { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px; }
        .checkbox-item { display: flex; align-items: center; font-size: 1rem; color: #555; }
        .checkbox-item input { margin-right: 10px; accent-color: #007BFF; }
        .submit-button { width: 100%; padding: 15px; background-color: #007BFF; color: white; border: none; border-radius: 5px; font-size: 1rem; cursor: pointer; transition: background-color 0.3s ease-in-out; }
        .submit-button:hover { background-color: #0056b3; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: center; }
        th { background-color: #007BFF; color: white; }
        td { background-color: #f9f9f9; }
        .error { color: red; font-size: 1.2rem; text-align: center; margin-top: 20px; }
    '])).

% Generate checkbox list for symptoms
checkbox_list([]) --> []. 
checkbox_list([Symptom|Rest]) -->
    html([div([class='checkbox-item'],
              [input([type=checkbox, name=symptom, value=Symptom, id=Symptom]),
               label([for=Symptom], Symptom)])]),
    checkbox_list(Rest).

% Diagnosis handler
diagnose_handler(Request) :-
    (   http_parameters(Request, [symptom(Symptoms, [list(atom)])])
    ->  diagnose_symptoms(Symptoms)
    ;   reply_html_page(
            title('Error'),
            [h1('Error'), p('No symptoms selected. Please go back and select at least one symptom.')]
        )
    ).

diagnose_symptoms(Symptoms) :-
    findall(Disease-Severity, diagnose(Disease, Symptoms, Severity), Diagnoses),
    ( Diagnoses = [] ->
        reply_html_page(
            title('Diagnosis Results'),
            [ h1('Diagnosis Results'),
              p([class='error'], 'No symptoms selected. Please go back and select at least one symptom.'),
              \diagnosis_table([])
            ]
        )
    ; reply_html_page(
        title('Diagnosis Results'),
        [ h1('Diagnosis Results'),
          \diagnosis_table(Diagnoses)
        ]
    )).

diagnosis_table([]) --> 
    html(p([class='error'], 'No diseases match the selected symptoms. Please try different symptoms.')).

diagnosis_table(Diagnoses) -->
    html([table([
        tr([th([style('border: 1px solid black; padding:10px')], 'Disease'),
             th([style('border: 1px solid black; padding:10px')], 'Severity'),
             th([style('border: 1px solid black; padding:10px')], 'Summary'),
             th([style('border: 1px solid black; padding:10px')], 'More Info')]),
        \diagnoses_rows(Diagnoses)
    ])]).

diagnoses_rows([]) --> []. 
diagnoses_rows([Disease-Severity|Rest]) -->
    { disease(Disease, DiseaseName),
      summary(Disease, Summary),
      link(Disease, Link) },
    html(tr([ 
        td([style('border: 1px solid black; padding:10px; text-align:center;')], DiseaseName),
        td([style('border: 1px solid black; padding:10px; text-align:center;')], Severity),
        td([style('border: 1px solid black; padding:10px; text-align:justify;')], Summary),
        td([style('border: 1px solid black; padding:10px; text-align:center;')], 
           a([href=Link, target='_blank', style='color:blue; text-decoration:none;'], 'More Info'))
    ])),
    diagnoses_rows(Rest).
