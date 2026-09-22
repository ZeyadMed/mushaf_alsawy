abstract interface class Endpoints {
  static const String baseUrl = 'https://islamhub.runasp.net';
  static const String surahs = '/api/application/surahs';
  static String surahContent(int number) => '$surahs/$number/content';
  static const String hadithMatns = '/api/application/hadith-matns';
  static const String hadiths = '/api/application/hadiths';
  static String hadith(int id) => '$hadiths/$id';
}
