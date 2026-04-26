// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Gerador QR e NFC';

  @override
  String get screenSplashSubtitle => 'Crie e personalize seu próprio código QR';

  @override
  String get tileAppAndroid => 'Abrir App';

  @override
  String get tileAppIos => 'Atalho';

  @override
  String get tileClipboard => 'Área de Transferência';

  @override
  String get tileWebsite => 'Site';

  @override
  String get tileContact => 'Contato';

  @override
  String get tileWifi => 'WiFi';

  @override
  String get tileLocation => 'Localização';

  @override
  String get tileEvent => 'Evento';

  @override
  String get tileEmail => 'E-mail';

  @override
  String get tileSms => 'SMS';

  @override
  String get screenHomeTitle => 'Gerador QR e NFC';

  @override
  String get screenHomeEditModeTitle => 'Modo de Edição';

  @override
  String get actionDone => 'Concluído';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Excluir';

  @override
  String get actionEdit => 'Editar';

  @override
  String actionDeleteCount(int count) {
    return 'Excluir $count';
  }

  @override
  String get actionSave => 'Salvar';

  @override
  String get actionShare => 'Compartilhar';

  @override
  String get actionRetry => 'Tentar novamente';

  @override
  String get actionClose => 'Fechar';

  @override
  String get actionConfirm => 'OK';

  @override
  String get tooltipHelp => 'Guia de uso';

  @override
  String get tooltipFavorite => '즐겨찾기';

  @override
  String get tooltipUnfavorite => '즐겨찾기 해제';

  @override
  String get tooltipHistory => 'Histórico';

  @override
  String get tooltipDeleteAll => 'Excluir tudo';

  @override
  String get actionCollapseHidden => 'Recolher menu oculto';

  @override
  String actionShowHidden(int count) {
    return 'Ver menu oculto ($count)';
  }

  @override
  String get screenHelpTitle => 'Guia de uso';

  @override
  String get screenHistoryTitle => 'Histórico';

  @override
  String get screenHistoryEmpty => 'Nenhum histórico.';

  @override
  String get labelQrCode => 'Código QR';

  @override
  String get labelNfcTag => 'Tag NFC';

  @override
  String get dialogClearAllTitle => 'Excluir tudo';

  @override
  String get dialogClearAllContent => 'Deseja excluir todo o histórico?';

  @override
  String get dialogDeleteHistoryTitle => 'Excluir histórico';

  @override
  String dialogDeleteHistoryContent(String name) {
    return 'Deseja excluir o histórico de \"$name\"?';
  }

  @override
  String get screenWebsiteTitle => 'Tag de Site';

  @override
  String get labelUrl => 'URL';

  @override
  String get hintUrl => 'https://example.com';

  @override
  String get msgUrlRequired => 'Por favor, insira uma URL.';

  @override
  String get msgUrlInvalid => 'Por favor, insira uma URL válida.';

  @override
  String get screenWifiTitle => 'Tag WiFi';

  @override
  String get labelWifiSsid => 'Nome da rede (SSID) *';

  @override
  String get hintWifiSsid => 'MyWiFi';

  @override
  String get msgSsidRequired => 'Por favor, insira o SSID.';

  @override
  String get labelWifiSecurity => 'Segurança';

  @override
  String get optionWpa2 => 'WPA2 (Recomendado)';

  @override
  String get optionNoSecurity => 'Nenhuma';

  @override
  String get labelWifiPassword => 'Senha';

  @override
  String get hintWifiPassword => 'Senha';

  @override
  String get screenSmsTitle => 'Tag SMS';

  @override
  String get labelPhoneRequired => 'Número de telefone *';

  @override
  String get hintPhone => '11-90000-0000';

  @override
  String get msgPhoneRequired => 'Por favor, insira um número de telefone.';

  @override
  String get labelMessageOptional => 'Mensagem (Opcional)';

  @override
  String get hintSmsMessage => 'Conteúdo da mensagem';

  @override
  String get screenEmailTitle => 'Tag de E-mail';

  @override
  String get labelEmailRequired => 'Endereço de e-mail *';

  @override
  String get hintEmail => 'example@email.com';

  @override
  String get msgEmailRequired => 'Por favor, insira um endereço de e-mail.';

  @override
  String get msgEmailInvalid => 'Por favor, insira um e-mail válido.';

  @override
  String get labelEmailSubjectOptional => 'Assunto (Opcional)';

  @override
  String get hintEmailSubject => 'Assunto do e-mail';

  @override
  String get labelEmailBodyOptional => 'Corpo (Opcional)';

  @override
  String get hintEmailBody => 'Corpo do e-mail';

  @override
  String get screenContactTitle => 'Tag de Contato';

  @override
  String get actionManualInput => 'Entrada manual';

  @override
  String get screenContactManualSubtitle =>
      'Insira nome, telefone e e-mail manualmente';

  @override
  String get hintSearchByName => 'Buscar por nome';

  @override
  String get labelNoPhone => 'Sem número de telefone';

  @override
  String get msgContactPermissionRequired =>
      'Permissão de acesso aos contatos necessária';

  @override
  String get msgContactPermissionHint =>
      'Use a entrada manual ou permita o acesso nas configurações.';

  @override
  String get actionOpenSettings => 'Abrir Configurações';

  @override
  String get msgSearchNoResults => 'Nenhum resultado encontrado.';

  @override
  String get msgNoContacts => 'Nenhum contato salvo.';

  @override
  String get screenContactManualTitle => 'Entrada manual';

  @override
  String get labelNameRequired => 'Nome *';

  @override
  String get hintName => 'João Silva';

  @override
  String get msgNameRequired => 'Por favor, insira um nome.';

  @override
  String get labelPhone => 'Telefone';

  @override
  String get labelEmail => 'E-mail';

  @override
  String get screenLocationTitle => 'Tag de Localização';

  @override
  String get screenLocationTapHint =>
      'Toque no mapa para selecionar uma localização.';

  @override
  String get msgSearchingAddress => 'Buscando endereço...';

  @override
  String get msgAddressUnavailable => 'Não foi possível obter o endereço.';

  @override
  String get labelPlaceNameOptional => 'Nome do local (Opcional)';

  @override
  String get hintPlaceName =>
      'Deixe vazio para usar o nome do edifício automaticamente.';

  @override
  String get msgSelectLocation =>
      'Por favor, selecione uma localização no mapa.';

  @override
  String get screenEventTitle => 'Tag de Evento';

  @override
  String get labelEventTitleRequired => 'Título do evento *';

  @override
  String get hintEventTitle => 'Título do evento';

  @override
  String get msgEventTitleRequired => 'Por favor, insira um título.';

  @override
  String get labelEventStart => 'Início';

  @override
  String get labelEventEnd => 'Fim';

  @override
  String get labelEventLocationOptional => 'Local/Endereço (Opcional)';

  @override
  String get hintEventLocation => 'Av. Paulista, 1000...';

  @override
  String get labelEventDescOptional => 'Descrição (Opcional)';

  @override
  String get hintEventDesc => 'Descrição do evento';

  @override
  String get msgEventEndBeforeStart =>
      'O horário de término deve ser após o horário de início.';

  @override
  String get screenClipboardTitle => 'Tag da Área de Transferência';

  @override
  String get msgClipboardEmpty =>
      'A área de transferência está vazia. Insira o texto manualmente.';

  @override
  String get labelContent => 'Conteúdo';

  @override
  String get hintClipboardText => 'Texto para salvar no tag';

  @override
  String get msgContentRequired => 'Por favor, insira o conteúdo.';

  @override
  String get screenIosInputTitle => 'Configuração de App iOS';

  @override
  String get labelShortcutName => 'Nome do atalho do app a executar';

  @override
  String get hintShortcutName => 'Ex: MeuApp';

  @override
  String get msgAppNameRequired => 'Por favor, insira o nome do app.';

  @override
  String get screenIosInputGuideTitle => 'Guia de configuração de atalhos';

  @override
  String get screenIosInputGuideSteps =>
      '1. Abra o app Atalhos (Shortcuts) no seu iPhone\n2. Crie um atalho que abra o app desejado\n3. Salve o atalho com o nome inserido acima\n4. Pressione o botão abaixo para gerar QR/NFC';

  @override
  String get actionAppleShortcutsGuide => 'Guia oficial de Atalhos da Apple';

  @override
  String get screenAppPickerTitle => 'Selecionar App';

  @override
  String get hintAppSearch => 'Buscar apps...';

  @override
  String get msgAppListError => 'Não foi possível carregar a lista de apps.';

  @override
  String get msgSelectApp => 'Por favor, selecione um app.';

  @override
  String get screenNfcWriterTitle => 'Gravação NFC';

  @override
  String get msgNfcWaiting =>
      'Aproxime o tag NFC da\nparte traseira do telefone';

  @override
  String get msgNfcSuccess => 'Gravação concluída!\nVoltando para o início...';

  @override
  String get msgNfcError => 'A gravação NFC falhou.';

  @override
  String get labelNfcIncludeIos => 'Incluir atalho iOS';

  @override
  String get labelIosShortcutName => 'Nome do atalho iOS';

  @override
  String get hintIosShortcutName => 'Ex: WhatsApp';

  @override
  String get screenOutputSelectorTitle => 'Selecionar método de saída';

  @override
  String get screenOutputQrDesc => 'Escaneie com a câmera para abrir o app';

  @override
  String get screenOutputNfcDesc => 'Aproxime o tag para abrir o app';

  @override
  String get msgNfcCheckFailed => 'Verificação NFC falhou';

  @override
  String get msgNfcSimulator => 'Não é possível testar NFC no simulador';

  @override
  String get msgNfcNotSupported => 'Este dispositivo não suporta NFC';

  @override
  String get msgNfcWriteIosMin =>
      'A gravação NFC requer iPhone XS ou posterior';

  @override
  String get msgNfcUnsupportedDevice => 'Dispositivo sem suporte NFC';

  @override
  String get actionNfcWrite => 'Gravar tag NFC';

  @override
  String get screenQrResultTitle => 'Código QR';

  @override
  String get tabTemplate => 'Modelo';

  @override
  String get tabShape => 'Forma';

  @override
  String get tabBackground => '배경';

  @override
  String get tabColor => 'Cor';

  @override
  String get tabLogo => 'Logo';

  @override
  String get tabText => 'Texto';

  @override
  String get actionSaveGallery => 'Salvar na Galeria';

  @override
  String get actionSaveSvg => 'SVG 저장';

  @override
  String get actionSaveTemplate => 'Salvar Modelo';

  @override
  String get dialogLowReadabilityTitle => 'Legibilidade baixa';

  @override
  String dialogLowReadabilityScore(int score) {
    return 'Legibilidade atual: $score%';
  }

  @override
  String get dialogLowReadabilityWarning =>
      'O código QR pode não ser reconhecido\npor alguns leitores.';

  @override
  String dialogLowReadabilityCause(String issue) {
    return 'Causa principal: $issue';
  }

  @override
  String get actionSaveAnyway => 'Salvar mesmo assim';

  @override
  String get dialogSaveTemplateTitle => 'Salvar Modelo';

  @override
  String get labelTemplateName => 'Nome do modelo';

  @override
  String get hintTemplateName => 'Ex: QR fundo azul';

  @override
  String msgTemplateSaved(String name) {
    return 'Modelo \"$name\" foi salvo.';
  }

  @override
  String get msgSaveFailed => 'Falha ao salvar a imagem.';

  @override
  String get msgPrintFailed =>
      'Falha na impressão. Verifique a conexão da impressora.';

  @override
  String get labelReadability => 'Legibilidade';

  @override
  String get screenTemplateMyTemplates => 'Meus Modelos';

  @override
  String get templateSectionFavorites => '내 즐겨찾기';

  @override
  String get templateEmptyFavorites =>
      '즐겨찾기한 QR이 없습니다.\n홈 화면에서 QR을 즐겨찾기에 추가해 보세요.';

  @override
  String get dialogDeleteTemplateTitle => 'Excluir Modelo';

  @override
  String dialogDeleteTemplateContent(String name) {
    return 'Deseja excluir \"$name\"?';
  }

  @override
  String get msgNoSavedTemplates => 'Nenhum modelo salvo.';

  @override
  String get msgNoSavedTemplatesHint =>
      'Salve o estilo atual com o botão [Salvar Modelo] abaixo.';

  @override
  String get tabColorSolid => 'Sólido';

  @override
  String get tabColorGradient => 'Gradiente';

  @override
  String get colorTargetBoth => '동시';

  @override
  String get colorTargetQr => 'QR';

  @override
  String get colorTargetBg => '배경';

  @override
  String get actionPickColor => 'Escolher cor';

  @override
  String get labelRecommendedColors => 'Cores recomendadas';

  @override
  String get labelGradientPresets => 'Presets de gradiente';

  @override
  String get dialogColorPickerTitle => 'Escolher cor';

  @override
  String get labelDotShape => 'Forma do ponto';

  @override
  String get labelEyeOuter => 'Forma do olho — Externo';

  @override
  String get labelEyeInner => 'Forma do olho — Interno';

  @override
  String get shapeSquare => 'Quadrado';

  @override
  String get shapeRounded => 'Arredondado';

  @override
  String get shapeCircle => 'Círculo';

  @override
  String get shapeCircleRound => 'Círculo rosquinha';

  @override
  String get shapeSmooth => 'Suave';

  @override
  String get shapeDiamond => 'Losango';

  @override
  String get shapeStar => 'Estrela';

  @override
  String get actionClear => 'Limpar';

  @override
  String get labelShowIcon => 'Mostrar ícone';

  @override
  String get msgIconUnavailable =>
      'Exibido apenas quando um ícone de app ou emoji está definido.';

  @override
  String get labelLogoPosition => 'Posição do logo';

  @override
  String get optionCenter => 'Centro';

  @override
  String get optionBottomRight => 'Inferior direito';

  @override
  String get labelLogoBackground => 'Fundo do logo';

  @override
  String get optionNone => 'Nenhum';

  @override
  String get optionSquare => 'Quadrado';

  @override
  String get optionCircle => 'Círculo';

  @override
  String get labelTopText => 'Texto superior';

  @override
  String get labelCenterText => '중앙';

  @override
  String get labelBottomText => 'Texto inferior';

  @override
  String get labelBandHorizontal => '가로띠';

  @override
  String get labelBandVertical => '세로띠';

  @override
  String get labelBgSquare => '사각';

  @override
  String get labelBgCircle => '원형';

  @override
  String get labelTextBackground => '배경';

  @override
  String get optionTextBgNone => '없음';

  @override
  String get optionTextBgFilled => '채움';

  @override
  String get labelTextBgColor => '배경색';

  @override
  String get labelTextColor => '글자색';

  @override
  String get labelTextSize => '크기';

  @override
  String get hintEnterText => 'Insira o texto';

  @override
  String get screenSettingsTitle => 'Configurações';

  @override
  String get drawerSvgStorage => 'SVG 저장함';

  @override
  String get svgStorageEmpty => '저장된 SVG 파일이 없습니다';

  @override
  String get svgStorageDeleteConfirm => '이 SVG 파일을 삭제하시겠습니까?';

  @override
  String get drawerAppInfo => '프로그램 정보';

  @override
  String get appInfoBuild => '빌드';

  @override
  String get appInfoTemplateEngine => '템플릿 엔진';

  @override
  String get appInfoTemplateSchema => '템플릿 스키마';

  @override
  String get legalPrivacyPolicy => '개인정보처리방침';

  @override
  String get legalTermsOfService => '이용약관';

  @override
  String get legalAccountDeletion => '계정 삭제 안내';

  @override
  String get legalSupport => '문의하기';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Padrão do sistema';

  @override
  String msgCopiedToClipboard(String text) {
    return '\"$text\" copiado para a área de transferência';
  }

  @override
  String get settingsReadabilityAlert => 'Alerta de legibilidade';

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iOS';

  @override
  String get labelCustomGradient => 'Gradiente personalizado';

  @override
  String get labelGradientType => 'Tipo';

  @override
  String get optionLinear => 'Linear';

  @override
  String get optionRadial => 'Radial';

  @override
  String get labelAngle => 'Ângulo';

  @override
  String get labelCenter => 'Centro';

  @override
  String get optionCenterCenter => 'Centro';

  @override
  String get optionCenterTopLeft => 'Superior esquerdo';

  @override
  String get optionCenterTopRight => 'Superior direito';

  @override
  String get optionCenterBottomLeft => 'Inferior esquerdo';

  @override
  String get optionCenterBottomRight => 'Inferior direito';

  @override
  String get labelColorStops => 'Pontos de cor';

  @override
  String get actionAddStop => 'Adicionar';

  @override
  String get actionDeleteStop => 'Excluir';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get signupTitle => 'Cadastrar';

  @override
  String get continueWithGoogle => 'Continuar com Google';

  @override
  String get continueWithApple => 'Continuar com Apple';

  @override
  String get loginWithEmail => 'Entrar com email';

  @override
  String get useWithoutLogin => 'Usar sem login';

  @override
  String get orDivider => 'ou';

  @override
  String get noAccountYet => 'Não tem uma conta?';

  @override
  String get signUp => 'Cadastrar';

  @override
  String get nickname => 'Apelido';

  @override
  String get email => 'Email';

  @override
  String get password => 'Senha';

  @override
  String get passwordConfirm => 'Confirmar senha';

  @override
  String get passwordMinLength => 'A senha deve ter pelo menos 8 caracteres';

  @override
  String get passwordMismatch => 'As senhas não coincidem';

  @override
  String get invalidEmail => 'Digite um email válido';

  @override
  String get nicknameRequired => 'Digite um apelido';

  @override
  String get profileTitle => 'Meu Perfil';

  @override
  String get changePhoto => 'Alterar foto';

  @override
  String get loginMethod => 'Método de login';

  @override
  String get joinDate => 'Data de registro';

  @override
  String get syncStatus => 'Status de sincronização';

  @override
  String get synced => 'Sincronizado';

  @override
  String get syncing => 'Sincronizando...';

  @override
  String get syncError => 'Falha na sincronização';

  @override
  String get lastSynced => 'Última sincronização';

  @override
  String get justNow => 'Agora mesmo';

  @override
  String get manualSync => 'Sincronizar agora';

  @override
  String get logout => 'Sair';

  @override
  String get deleteAccount => 'Excluir conta';

  @override
  String get deleteAccountConfirm =>
      'Deseja excluir sua conta? Todos os dados na nuvem serão apagados.';

  @override
  String get logoutConfirm => 'Deseja sair? Os dados locais serão mantidos.';

  @override
  String get accountSection => 'Conta';

  @override
  String get syncSection => 'Sincronização';

  @override
  String get loginPrompt => 'Entrar';

  @override
  String get cloudSync => 'Sincronização na nuvem';

  @override
  String get cancel => 'Cancelar';

  @override
  String get labelSavePreset => 'Salvar preset';

  @override
  String get hintPresetName => 'Nome do preset';

  @override
  String get labelBoundaryShape => 'Forma do contorno QR';

  @override
  String get labelAnimation => 'Animação';

  @override
  String get labelCustomDot => 'Ponto personalizado';

  @override
  String get labelCustomEye => 'Olho personalizado';

  @override
  String get labelCustomBoundary => 'Contorno personalizado';

  @override
  String get labelCustomAnimation => 'Animação personalizada';

  @override
  String get actionApply => 'Aplicar';

  @override
  String get sliderVertices => 'Vértices';

  @override
  String get sliderInnerRadius => 'Raio interno';

  @override
  String get sliderRoundness => 'Arredondamento';

  @override
  String get sliderRotation => 'Rotação';

  @override
  String get sliderDotScale => 'Tamanho';

  @override
  String get labelSymmetric => 'Simétrico';

  @override
  String get labelAsymmetric => 'Assimétrico';

  @override
  String get sliderSfM => 'Simetria (m)';

  @override
  String get sliderSfN1 => 'Curvatura 1';

  @override
  String get sliderSfN2 => 'Curvatura 2';

  @override
  String get sliderSfN3 => 'Curvatura 3';

  @override
  String get sliderSfA => 'Escala X';

  @override
  String get sliderSfB => 'Escala Y';

  @override
  String get sliderOuterN => 'Forma externa';

  @override
  String get sliderInnerN => 'Forma interna';

  @override
  String get sliderCornerQ1 => 'Q1 모서리';

  @override
  String get sliderCornerQ2 => 'Q2 모서리';

  @override
  String get sliderCornerQ3 => 'Q3 모서리';

  @override
  String get sliderCornerQ4 => 'Q4 모서리';

  @override
  String get labelBoundaryType => 'Tipo de contorno';

  @override
  String get sliderSuperellipseN => 'Forma N';

  @override
  String get sliderStarVertices => 'Pontas da estrela';

  @override
  String get sliderStarInnerRadius => 'Profundidade';

  @override
  String get sliderPadding => 'Preenchimento';

  @override
  String get sliderFrameScale => '프레임 크기';

  @override
  String get labelMarginPattern => '마진 패턴';

  @override
  String get sliderPatternDensity => '패턴 밀도';

  @override
  String get patternNone => '없음';

  @override
  String get patternQrDots => '도트';

  @override
  String get patternMaze => '미로';

  @override
  String get patternZigzag => '지그재그';

  @override
  String get patternWave => '물결';

  @override
  String get patternGrid => '격자';

  @override
  String get labelFrameColors => '프레임 색상';

  @override
  String get labelBorderStyle => '선 종류';

  @override
  String get labelBorderColor => '선 색상';

  @override
  String get sliderBorderWidth => '선 두께';

  @override
  String get labelPatternColor => '패턴 색상';

  @override
  String get borderNone => '없음';

  @override
  String get borderSolid => '실선';

  @override
  String get borderDashed => '파선';

  @override
  String get borderDotted => '점선';

  @override
  String get borderDashDot => '일점쇄선';

  @override
  String get borderDouble => '이중선';

  @override
  String get boundaryNone => '없음';

  @override
  String get boundaryCircle => '원형';

  @override
  String get boundarySuperellipse => '슈퍼타원';

  @override
  String get boundaryStar => '별';

  @override
  String get boundaryHeart => '하트';

  @override
  String get boundaryHexagon => '육각형';

  @override
  String get labelFontFamily => '글꼴';

  @override
  String get sliderSpeed => 'Velocidade';

  @override
  String get sliderAmplitude => 'Amplitude';

  @override
  String get sliderFrequency => 'Frequência';

  @override
  String get optionLogoTypeLogo => 'Logo';

  @override
  String get optionLogoTypeImage => 'Imagem';

  @override
  String get optionLogoTypeText => 'Texto';

  @override
  String get labelLogoTabPosition => 'Posição';

  @override
  String get labelLogoTabBackground => 'Fundo';

  @override
  String get labelLogoCategory => 'Categoria';

  @override
  String get labelLogoGallery => 'Escolher da galeria';

  @override
  String get labelLogoRecrop => 'Recortar';

  @override
  String get labelLogoTextContent => 'Texto';

  @override
  String get hintLogoTextContent => 'Texto do logotipo';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryCoin => 'Moeda';

  @override
  String get categoryBrand => 'Marca';

  @override
  String get categoryEmoji => 'Emoji';

  @override
  String get msgLogoLoadFailed => 'Não foi possível carregar o ícone';

  @override
  String get msgLogoCropFailed => 'Falha ao processar imagem';

  @override
  String get labelLogoBackgroundColor => 'Cor';

  @override
  String get actionLogoBackgroundReset => 'Padrão';

  @override
  String get optionRectangle => 'Quadrado';

  @override
  String get optionRoundedRectangle => 'Círculo';

  @override
  String get labelLogoType => 'Tipo';

  @override
  String get tileScanner => 'QR 스캐너';

  @override
  String get scannerPermissionTitle => '카메라 권한 필요';

  @override
  String get scannerPermissionDesc => 'QR 코드를 스캔하려면 카메라 접근 권한이 필요합니다.';

  @override
  String get scannerPermissionOpenSettings => '설정으로 이동';

  @override
  String get scannerPermissionGalleryFallback => '갤러리에서 선택';

  @override
  String get scannerFlashOn => '플래시 켜기';

  @override
  String get scannerFlashOff => '플래시 끄기';

  @override
  String get scannerGalleryImport => '갤러리에서 QR 코드 불러오기';

  @override
  String get scannerGalleryFail => '이미지에서 QR 코드를 인식할 수 없습니다.';

  @override
  String get scanResultTitle => '스캔 결과';

  @override
  String get scanActionOpenBrowser => '열기';

  @override
  String get scanActionCopyLink => '링크 복사';

  @override
  String get scanActionCopySsid => 'SSID 복사';

  @override
  String get scanActionCopyPassword => '비밀번호 복사';

  @override
  String get scanActionCopyAll => '전체 복사';

  @override
  String get scanActionShare => '공유';

  @override
  String get scanActionOpenApp => '앱 열기';

  @override
  String get scanActionCustomize => '꾸미기';

  @override
  String get historyTabCreated => '생성이력';

  @override
  String get historyTabScanned => '스캔이력';

  @override
  String get historySearchHint => '검색...';

  @override
  String get historyFilterAll => '전체';

  @override
  String get historyEmpty => '이력이 없습니다.';

  @override
  String get actionFavorite => '즐겨찾기';

  @override
  String get actionStartCustomize => 'QR 만들기';

  @override
  String get actionNext => '다음';

  @override
  String get actionCreateNew => '새로 만들기';

  @override
  String get actionEditAgain => '편집하기';

  @override
  String get actionRename => '이름 변경';

  @override
  String get sheetCreateTitle => '새로 만들기';

  @override
  String get homeEmptyTitle => '첫 QR을 만들어 보세요';

  @override
  String get dialogRenameTitle => '이름 변경';

  @override
  String get hintTaskName => '작업 이름';

  @override
  String get dialogDeleteTitle => '삭제';

  @override
  String dialogDeleteContent(String name) {
    return '$name 을(를) 삭제하시겠습니까?';
  }

  @override
  String get msgNoThumbnail => '미리보기 이미지가 없습니다';

  @override
  String get msgSavedToGallery => '갤러리에 저장되었습니다';

  @override
  String get msgSvgSaved => 'SVG 파일이 저장되었습니다';

  @override
  String get labelQr => 'QR';

  @override
  String get timeJustNow => '방금';

  @override
  String timeMinutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get actionSelectAll => '모두선택';

  @override
  String get actionDeleteAll => '모두삭제';

  @override
  String get dialogDeleteAllTitle => '전체 삭제';

  @override
  String get dialogDeleteAllContent => '모든 QR을 삭제하시겠습니까?';

  @override
  String get dialogDeleteSelectedTitle => '선택 삭제';

  @override
  String dialogDeleteSelectedContent(int count) {
    return '$count개의 QR을 삭제하시겠습니까?';
  }

  @override
  String get labelEvenSpacing => '균등 분할';
}
