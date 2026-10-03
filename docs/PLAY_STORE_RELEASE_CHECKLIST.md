# Preparação de publicação

Build de desenvolvimento atual não é release público. Godot 4.7.2, Compatibility, landscape, ARM64. Meta: 60 FPS quando possível; medir no aparelho, não inferir de headless.

- [ ] Todos assets redistribuíveis registrados e aprovados pelo gate de release; UNKNOWN_LICENSE/DEVELOPMENT_ONLY bloqueados.
- [ ] Créditos para NEEDS_ATTRIBUTION e provas de distribuição disponíveis; apresentação/personagens/marcas também revisados. [Política oficial de propriedade intelectual](https://support.google.com/googleplay/android-developer/answer/9888072).
- [ ] Application ID definitivo, versionCode/versionName, AAB, templates Godot e target API conferidos nas exigências atuais da Play Console.
- [ ] Bibliotecas nativas compatíveis com [páginas de 16 KB](https://developer.android.com/guide/practices/page-sizes).
- [ ] Signing por variáveis/arquivos privados fora do Git; nunca commitar keystore/senha/token.
- [ ] Adaptive icon/splash originais, classificação indicativa, ficha/prints próprios.
- [ ] Permissões mínimas, declaração de dados e política de privacidade quando aplicável.
- [ ] Saves versionados, persistência entre atualizações, pause/resume/background sem perda de input/controle.
- [ ] Testes ARM64, LOW/MEDIUM/HIGH, multitouch, FPS/temperatura/memória, duração prolongada e tamanho final.
- [ ] Narração/áudio/modelos/animações próprios ou autorizados; nenhum download runtime.

O modelo rigged.glb fornecido continua utilizável no desenvolvimento, mas sua licença não foi comprovada. Isso deve bloquear o release público até autorização verificável ou substituição adequada; não é motivo para apagar o rig atual.

O mundo agora adiciona o autoload GameFlow. Quando o preset público é rejeitado, o plugin suspende autoloads somente na configuração do container bloqueado e restaura valores/ordem no fim do export; não salva alterações no project.godot. Isso evita inicializar scripts com recursos ausentes. Container bloqueado continua não publicável, e o contrato isolado verifica ausência de main/modelo/world e do autoload dependente.
