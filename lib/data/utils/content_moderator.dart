class ContentModerator {
  static const Set<String> _inappropriateWords = {
    // Explicit Sexual Content
    "bugil",
    "telanjang",
    "porno",
    "seks",
    "vulgar",
    "cabul",
    "mesum",
    "asusila",
    "erotis",
    "sensual",
    "birahi",
    "nafsu",
    "syahwat",
    "lonte",
    "pelacur",
    "jablay",
    "bokep",
    "ngentot",
    "memek",
    "kontol",
    "ngewe",
    "jembut",
    "itil",
    "toket",
    "pentil",
    "perek",
    "germo",
    "sundal",
    "vagina",
    "pussy",
    "cunt",
    "coochie",
    "twat",
    "penis",
    "cock",
    "dick",
    "prick",
    "schlong",
    "dong",
    "testicles",
    "scrotum",
    "anus",
    "asshole",
    "butt",
    "booty",
    "bum",
    "arse",
    "rectum",
    "breast",
    "boob",
    "tits",
    "nipple",
    "areola",
    "clitoris",
    "labia",
    "vulva",
    "semen",
    "sperm",
    "cum",
    "jizz",
    "spunk",
    "ejaculate",
    "orgasm",
    "climax",
    "masturbation",
    "handjob",
    "blowjob",
    "fellatio",
    "cunnilingus",
    "rimjob",
    "anilingus",
    "fingering",
    "fisting",
    "intercourse",
    "coitus",
    "copulation",
    "fucking",
    "screwing",
    "banging",
    "shagging",
    "doggy style",
    "missionary position",
    "69",
    "anal sex",
    "oral sex",
    "group sex",
    "orgy",
    "gangbang",
    "threesome",
    "foursome",
    "incest",
    "bestiality",
    "zoophilia",
    "pedophilia",
    "necrophilia",
    "rape",
    "sexual assault",
    "sexual abuse",
    "molestation",
    "prostitute",
    "sex",
    "sexy",
    "porn",
    "boobs",
    "nude",
    "naked",
    "whore",
    "hooker",
    "slut",
    "harlot",
    "tramp",
    "pimp",
    "brothel",
    "sex worker",
    "pornstar",
    "adult entertainer",
    "stripper",
    "hentai",
    "nsfw",
    "explicit",
    "18+",
    "xxx",
    "hardcore",
    "softcore",
    "gonzo",
    "bukkake",
    "creampie",
    "deepthroat",
    "double penetration",
    "facial",
    "gloryhole",
    "undress",
    "seeing through clothes",
    "x-ray",

    // Strong Profanity & Insults
    "bajingan",
    "bangsat",
    "keparat",
    "biadab",
    "kurang ajar",
    "brengsek",
    "anjing",
    "babi",
    "monyet",
    "sampah",
    "tolol",
    "goblok",
    "idiot",
    "dungu",
    "bodoh",
    "fuck",
    "shit",
    "piss",
    "crap",
    "bullshit",
    "motherfucker",
    "bitch",
    "bastard",
    "dickhead",
    "damn", "goddamn", "what the fuck", "wtf",

    // Hate Speech & Derogatory Terms
    "rasis", "sara",
  };

  static const Map<String, String> _variationWords = {
    "s3x": "sex",
    "s3xy": "sexy",
    "s3ks": "seks",
    "p0rn": "porn",
    "p0rno": "porno",
    "b00bs": "boobs",
    "t1ts": "tits",
    "d1ck": "dick",
    "c0ck": "cock",
    "f*ck": "fuck",
    "fck": "fuck",
    "sh1t": "shit",
    "b1tch": "bitch",
    "@ss": "ass",
    "a\$\$": "ass",
    "nud3": "nude",
    "n4k3d": "naked",
  };

  /// Returns a list of inappropriate words found in the prompt.
  /// If the list is empty, the prompt is clean.
  static List<String> checkPrompt(String prompt) {
    if (prompt.isEmpty) return [];

    final foundWords = <String>[];
    final normalizedPrompt = prompt.toLowerCase();

    // Split into words, handling common separators
    final words = normalizedPrompt.split(
      RegExp(r'\s+|,|;|\.|!|\?|\n|\t|\[|\]|\(|\)'),
    );

    // Check direct matches
    for (final word in words) {
      if (word.isEmpty) continue;

      // Cleanup punctuation from word start/end
      final cleanWord = word.replaceAll(
        RegExp(r'^[^a-zA-Z0-9@$!*]+|[^a-zA-Z0-9@$!*]+$'),
        '',
      );

      if (cleanWord.isEmpty) continue;

      // 1. Direct inappropriate word match
      if (_inappropriateWords.contains(cleanWord)) {
        foundWords.add(cleanWord);
        continue;
      }

      // 2. Direct variation match
      if (_variationWords.containsKey(cleanWord)) {
        foundWords.add(cleanWord);
        continue;
      }

      // 3. Leetspeak normalization per word
      final normalizedLeet = cleanWord
          .replaceAll('3', 'e')
          .replaceAll('1', 'i')
          .replaceAll('0', 'o')
          .replaceAll('5', 's')
          .replaceAll('7', 't')
          .replaceAll('@', 'a')
          .replaceAll('\$', 's')
          .replaceAll('+', 't')
          .replaceAll('!', 'i')
          .replaceAll('|', 'i')
          .replaceAll('8', 'b')
          .replaceAll('9', 'g')
          .replaceAll('2', 'z')
          .replaceAll('4', 'a')
          .replaceAll('6', 'g');

      if (_inappropriateWords.contains(normalizedLeet) ||
          _variationWords.containsValue(normalizedLeet)) {
        foundWords.add(cleanWord);
      }
    }

    // Pattern based detection for sensitive words that might be joined
    // E.g. fotobugil, hothentai.
    // We strictly use words that have zero risk of false positives in normal English/Indonesian.
    // We REMOVED "sex", "porn", "naked" to avoid the Scunthorpe problem (e.g. Middlesex, sextant).
    final substringTargets = [
      "hentai",
      "bugil",
      "necrophilia",
      "pedophilia",
      "zoophilia",
      "bestiality",
      "bukkake",
      "creampie",
    ];

    for (final target in substringTargets) {
      if (normalizedPrompt.contains(target)) {
        foundWords.add(target);
      }
    }

    return foundWords.toSet().toList(); // Unique words
  }
}
