class QcmGeneratorJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 10.seconds, attempts: 3

  def perform(card_id)
    card = Card.find(card_id)
    return if card.qcm_choices.present?

    system_prompt = <<~PROMPT
      Tu es un générateur de QCM. On te donne une question et sa bonne réponse.
      Génère exactement 3 mauvaises réponses plausibles et cohérentes avec le sujet, mais clairement incorrectes.
      Retourne uniquement un tableau JSON de 3 chaînes de caractères.
      Aucun commentaire, aucune explication.
      Exemple : ["Faux 1", "Faux 2", "Faux 3"]
    PROMPT

    user_prompt = "Question : #{card.ask}\nBonne réponse : #{card.answer}"

    raw        = RubyLLM.chat(model: "gpt-4o-mini").with_instructions(system_prompt).ask(user_prompt).content
    distractors = JSON.parse(raw)

    return unless distractors.is_a?(Array) && distractors.size == 3

    choices = ([card.answer] + distractors).shuffle
    card.update_columns(qcm_choices: choices)
  rescue JSON::ParserError
  end
end
