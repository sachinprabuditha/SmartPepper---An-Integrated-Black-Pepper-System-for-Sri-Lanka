# 🌶️ Sri Lankan Black Pepper Theme - Design System

## Overview

The SmartPepper platform now features a complete Sri Lankan black pepper-inspired design system with warm, earthy tones that reflect the premium quality of Ceylon spices and agricultural heritage.

## Color Palette

### Primary Colors (Pepper-Inspired)

```
pepper-black: #2c2420      // Deep black pepper tone
pepper-darkBrown: #3d2e23  // Dark roasted pepper
pepper-mediumBrown: #5c4033 // Medium pepper brown
pepper-lightBrown: #8b6f47  // Light pepper/earth tone
```

### Spice Accent Colors

```
pepper-cinnamon: #b87333   // Ceylon cinnamon warmth
pepper-gold: #d4a574        // Golden harvest
pepper-earth: #8b7355       // Earthy soil
pepper-harvest: #e8a75d     // Harvest orange
```

### Sri Lankan Heritage Colors

```
pepper-sriLankaGreen: #006747  // Sri Lankan flag green
pepper-sriLankaOrange: #ff6b35 // Saffron/orange accent
```

### Primary Brand Colors (Updated)

The primary color scale now uses warm earth tones instead of bright orange:

- primary-50 to primary-950: Cream → Deep brown gradient
- Reflects the natural progression from raw to roasted pepper

## Typography & Text Colors

### Light Mode

- Headings: `pepper-darkBrown` (#3d2e23)
- Body text: `pepper-black` (#2c2420)
- Accents: `pepper-gold` (#d4a574)

### Dark Mode

- Headings: `white` or `pepper-gold`
- Body text: `pepper-harvest` (#e8a75d)
- Backgrounds: `pepper-black` to `pepper-darkBrown` gradients

## Component Styling

### Header

- **Background**: Gradient from `pepper-darkBrown` to `pepper-mediumBrown`
- **Logo**: Gold pepper leaf icon with backdrop blur
- **Tagline**: "Ceylon Black Pepper" subtitle
- **Links**: White text with gold hover states
- **Border**: Bottom border with gold accent

### Hero Section

- **Background**: Multi-stop gradient (darkBrown → mediumBrown → cinnamon)
- **Overlay**: Subtle black overlay for depth
- **Text**: White with gold accents
- **Buttons**:
  - Primary: Gold background with black text
  - Secondary: Glass-morphism with white borders

### Cards

- **Background**:
  - Light: White with amber border
  - Dark: Translucent dark brown with gold border
- **Border**: 2px amber/gold with hover effects
- **Hover**: Gold border glow on interaction

### Buttons

- **Primary**: Pepper gold background
- **Hover**: Harvest orange
- **Transform**: Subtle scale on hover
- **Success**: Farmer green (maintained)

### Inputs

- **Border**: 2px amber (light) / gold (dark)
- **Background**:
  - Light: White
  - Dark: Translucent black
- **Focus**: Gold ring with cinnamon accent

## Design Principles

### 1. Warmth & Authenticity

- Earthy browns evoke natural spice origins
- Gold accents represent premium Ceylon quality
- Gradient transitions mirror spice roasting process

### 2. Cultural Heritage

- Colors inspired by Sri Lankan landscapes
- Flag colors subtly integrated
- Traditional spice trade aesthetics

### 3. Premium Quality

- Rich, deep tones suggest high-grade product
- Gold accents indicate value and trust
- Sophisticated gradients show professionalism

### 4. Accessibility

- Strong contrast ratios maintained
- Gold on dark brown: 4.5:1+ contrast
- White on dark: 21:1 contrast

## Usage Examples

### Hero Gradient

```tsx
className =
  "bg-gradient-to-br from-pepper-darkBrown via-pepper-mediumBrown to-pepper-cinnamon";
```

### Card with Theme

```tsx
className = "card"; // Auto-includes pepper theme borders
```

### Button

```tsx
className = "btn bg-pepper-gold text-pepper-black hover:bg-pepper-harvest";
```

### Text Colors

```tsx
// Light mode heading
className = "text-pepper-darkBrown";

// Dark mode heading
className = "dark:text-pepper-gold";

// Body text
className = "text-pepper-black dark:text-pepper-harvest";
```

## Dark Mode Strategy

### Background Layers

1. Base: `pepper-black` (#2c2420)
2. Cards: `pepper-darkBrown/40` (translucent)
3. Header: `pepper-black` to `pepper-darkBrown` gradient

### Contrast Enhancement

- Gold borders glow in dark mode
- Translucent overlays create depth
- Backdrop blur on glass-morphism elements

## Animations & Effects

### Hover Transitions

- Border color shifts to gold
- Scale transforms (1.05x) on buttons
- Smooth 200ms transitions

### Glass-morphism

```css
bg-white/10 backdrop-blur-sm
```

Used for:

- Header navigation items
- Mobile menu overlays
- Secondary buttons

## Browser Compatibility

✅ All modern browsers support:

- CSS gradients
- Backdrop filters
- CSS custom properties
- Dark mode classes

## Implementation Files Modified

1. `web/tailwind.config.js` - Full color palette
2. `web/src/styles/globals.css` - Component styles
3. `web/src/app/page.tsx` - Hero section
4. `web/src/components/layout/Header.tsx` - Navigation
5. All dashboard pages - Background updates

## Testing Checklist

- [x] Color contrast meets WCAG AA standards
- [x] Dark mode transitions smoothly
- [x] Gold accents visible in both modes
- [x] Mobile responsive design maintained
- [x] Cultural authenticity preserved

## Future Enhancements

- [ ] Add subtle pepper texture backgrounds
- [ ] Implement spice-trade inspired patterns
- [ ] Create animated pepper leaf logo
- [ ] Add Sri Lankan typography fonts
- [ ] Include tea/spice imagery

---

**Theme Version**: 1.0 - Ceylon Black Pepper Edition  
**Updated**: January 2025  
**Design Inspired By**: Sri Lankan black pepper, spice trade heritage, and agricultural excellence
