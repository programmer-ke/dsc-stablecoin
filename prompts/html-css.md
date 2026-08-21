We're using the following design principles we're using for HTML and CSS

# CSS Specifity

To avoid CSS specifity hell:

- Use semantic html tags (built-in or custom) for html elements
  instead of generic divs with classes
  - Create custom elements when necessary
  - custom elements are inline by default. Set style to block/inline
     block as necessary
- Use CSS classes only for different variants/states of the tags
  e.g. disabled, warning states
- Use CSS ids for one time localized changes for a single view

# CSS Display Property

- Stick to `block`, `flex` and `grid` for most elements

# Units of Measurement

- For most things, =em= and =rem= will suffice. Only use pixels where
  exact measurement is desired.
  
# Colour and Contrast

- Design first in monochrome so that contrast can be easily visualized and measured
- A colour scale like the following can be used:

```css
:root {
  /* light values */
  --value9: hsl(0, 0%, 100%);
  --value8: hsl(0, 0%, 99%);
  --value7: hsl(0, 0%, 90%);
  --value6: hsl(0, 0%, 85%);
  --value5: hsl(0, 0%, 80%);

  /* dark values */
  --value4: hsl(0, 0%, 44%);
  --value3: hsl(0, 0%, 33%);
  --value2: hsl(0, 0%, 22%);
  --value1: hsl(0, 0%, 11%);
  --value0: hsl(0, 0%, 1%);
}
```

- Typically, 5 values can be used to start with: 9, 7, 5, 3, 1

# Responsiveness

Make the UI responsive across mobile, tablet and desktop

# Important

- Use `mvp.css` for base styling

- Use `minstrap.css` for the layout

- Reuse as much of the provided CSS as possible. Only introduce
new styling when necessary.

- Prefer creating and using custom elements instead of using CSS
classes to identify elements. Use CSS classes only for different
variants or states of the same element.

