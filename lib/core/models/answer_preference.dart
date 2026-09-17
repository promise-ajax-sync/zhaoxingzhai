/// 解答偏好。
///
/// 三档对应参考实现里的 `answerPreferenceOptions`：
/// 日常聊天 / 算命大师 / 专业人士。前两者是摘要，第三者给出完整说明。
enum AnswerPreference {
  chat('chat', '日常聊天', '自然直说', '像熟悉你的朋友，用白话直接回答'),
  fortuneMaster('fortune-master', '算命大师', '传统断法', '先断主旨，再讲盘理、时机与趋避'),
  professional('professional', '专业人士', '严谨推演', '展开结构、条件、分歧与专业判断');

  const AnswerPreference(this.id, this.label, this.summary, this.description);

  final String id;
  final String label;
  final String summary;
  final String description;
}
