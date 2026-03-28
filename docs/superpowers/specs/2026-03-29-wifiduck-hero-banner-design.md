# Wifiduck Hero Banner Design

## Goal
Create a distinctive GitHub README hero banner for `wifiduck` that makes the project look serious, memorable, and immediately understandable on the repository landing page.

## Visual Direction
The banner should feel like packet forensics rather than generic SaaS branding. The look is dark, sharp, and technical, with layered signal-analysis motifs and a witty undertone.

Recommended mood:
- packet-forensics console
- terminal-grade typography
- high-contrast, dark background
- electric cyan / acid green accents
- subtle visual humor rather than a literal mascot

## Composition
Optimize for a wide GitHub hero banner, approximately `1600x640`.

Layout:
- left side: title and tagline block with very high contrast
- right side: abstract packet-analysis field with traces, grids, channel lines, radiotap-like overlays, and MLO-inspired link geometry
- include a subtle duck-shaped or duck-referential visual joke only if it can stay clever and understated

The image must still read well when GitHub scales it down in the README.

## Text
Keep the text minimal:
- `wifiduck`
- `SQL-first Wi-Fi packet forensics`
- tagline: `Sniff first. Guess later.`

The typography should feel intentional and premium, not playful in a childish way.

## Constraints
- Do not make the banner mascot-led.
- Do not use a generic stock-network background.
- Do not overload the image with too much small text.
- Keep enough negative space that the text remains readable on GitHub.
- Save the final asset into the repository so the README can reference it directly.

## Repository Changes
- Add the generated hero image under a stable path such as `docs/assets/hero-banner.png`
- Update `README.md` so the banner appears near the top of the GitHub project page
- Keep the README change minimal and compatible with GitHub markdown rendering

## Success Criteria
- The README looks materially better on GitHub at first glance.
- The banner communicates Wi-Fi packet analysis, not generic software.
- The tone feels witty, clever, and technical without becoming gimmicky.
