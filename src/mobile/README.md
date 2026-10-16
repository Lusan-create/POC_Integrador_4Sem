# Mobile — Aplicativo (Flutter)

Aplicativo usado no local do equipamento: lê o QR Code/código de barras, mostra os dados do ativo e
registra movimentações e ordens de serviço. Consome a API Django.

**Tecnologias:** Flutter 3 / Dart · mobile_scanner (câmera) · http · flutter_secure_storage · provider

## Executar no celular Android (recomendado)

1. No celular: **Configurações → Sobre o telefone →** toque 7 vezes em **Número da versão**.
   Depois, em **Opções do desenvolvedor**, ative **Depuração USB**.
2. Conecte o celular no PC pelo cabo e aceite a autorização de depuração.
3. Celular e PC devem estar **na mesma rede Wi-Fi**. Descubra o IP do PC com `ipconfig`.
4. Rode a API com `python manage.py runserver 0.0.0.0:8000` e libere a porta 8000 no firewall.
5. Execute:

```powershell
cd mobile
flutter pub get
flutter run --dart-define=API_URL=http://SEU_IP:8000/api
```

O endereço da API também pode ser trocado dentro do app, pelo menu (☰) → "Endereço do servidor".

### Instalar o APK sem cabo

```powershell
flutter build apk --dart-define=API_URL=http://SEU_IP:8000/api
```

Copie `build\app\outputs\flutter-apk\app-release.apk` para o celular e instale
(é preciso permitir "instalar apps de fontes desconhecidas").

## Executar no Chrome (sem celular)

```powershell
flutter run -d chrome --dart-define=API_URL=http://localhost:8000/api
```

A câmera usa a webcam do PC. Se não houver webcam, use a consulta pelo código digitado.

## Telas

| Tela | Requisitos |
|---|---|
| Abas CAMERA (câmera abre direto, pesquisa manual) e ATIVOS; Usuários no menu lateral (layout do Figma) e configuração do endereço da API | RF03, RF04 |
| Consultar: **Iniciar câmera** ou digitar o código | RF03, RF10, RNF02, RNF04 |
| Ativo localizado: patrimônio, nome, categoria, local, responsável, situação | RF04 |
| Registrar movimentação | RF07 |
| Abrir ordem de serviço | RF08 |
| Histórico (movimentações + OS) e atualização/conclusão de OS | RF09 |
| Ordens de serviço pendentes | RF08 |

Os tokens ficam no armazenamento seguro do aparelho (Android Keystore).
